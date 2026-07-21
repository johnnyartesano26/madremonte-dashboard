/* Ventas — Consolidado Madre Monte 2026
   Datos vivos desde Google Sheet público.
   Se activa al hacer clic en "Actualizar ventas". */

const SALES_SHEET_URL =
  "https://docs.google.com/spreadsheets/d/1WFq09-LDg4le6FqC9BnBZfKZXSmb8Kn195wnFZaEMys/gviz/tq?tqx=out:csv&sheet=Respuestas%20de%20formulario%201";

let ventasChart = null;
let clientesChart = null;

function cleanNumber(raw) {
  if (!raw) return 0;
  const s = String(raw).replace(/[$. ]/g, "").replace(",", ".").trim();
  const n = parseFloat(s);
  return isNaN(n) ? 0 : n;
}

function parseDate(raw) {
  if (!raw) return null;
  // DD/MM/YYYY
  const parts = String(raw).trim().split("/");
  if (parts.length === 3) {
    const d = parseInt(parts[0]), m = parseInt(parts[1]) - 1, y = parseInt(parts[2]);
    const dt = new Date(y, m, d);
    if (y >= 2025 && y <= 2027) return dt;
  }
  // Try MM/DD/YYYY or YYYY-MM-DD
  const dt = new Date(raw);
  if (!isNaN(dt.getTime()) && dt.getFullYear() >= 2025 && dt.getFullYear() <= 2027) {
    return dt;
  }
  return null;
}

function monthLabel(date) {
  const months = ["Ene", "Feb", "Mar", "Abr", "May", "Jun",
                  "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
  return months[date.getMonth()] + " " + date.getFullYear();
}

async function fetchSalesData() {
  const statusEl = document.getElementById("ventas-status");
  if (statusEl) statusEl.textContent = "Cargando...";

  try {
    const resp = await fetch(SALES_SHEET_URL);
    const csvText = await resp.text();
    return parseSalesCSV(csvText);
  } catch (e) {
    if (statusEl) statusEl.textContent = "Error al cargar datos.";
    console.error(e);
    return null;
  }
}

function parseSalesCSV(csvText) {
  const lines = csvText.trim().split("\n");
  if (lines.length < 2) return null;

  // The first line is headers but gviz wraps in quotes
  const headers = parseCSVLine(lines[0]);
  const data = [];

  for (let i = 1; i < lines.length; i++) {
    const cols = parseCSVLine(lines[i]);
    if (cols.length < 10) continue;

    const nombre = (cols[2] || "").trim();
    const factura = (cols[3] || "").trim();
    const valor = cleanNumber(cols[4]);
    const domicilio = cleanNumber(cols[5]);
    const observaciones = (cols[6] || "").trim();
    const fechaStr = (cols[1] || "").trim();
    const formaPago = (cols[7] || "").trim();
    const cuenta = (cols[8] || "").trim();
    const pagoRealizado = (cols[9] || "").trim();

    const fecha = parseDate(fechaStr);
    if (!fecha) continue;

    // Skip test/automation entries
    const nl = nombre.toLowerCase();
    if (nl.includes("automatización") || nl.includes("opción 1") || nl.includes("automatizacion")) continue;
    if (valor === 0 && domicilio === 0) continue;
    if (observaciones.toLowerCase().includes("nota crédito")) continue;

    data.push({ nombre, factura, valor, domicilio, fecha, formaPago, cuenta, pagoRealizado, observaciones });
  }

  return data;
}

function parseCSVLine(line) {
  const result = [];
  let current = "";
  let inQuotes = false;

  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (ch === '"') {
      if (inQuotes && line[i + 1] === '"') {
        current += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (ch === "," && !inQuotes) {
      result.push(current);
      current = "";
    } else {
      current += ch;
    }
  }
  result.push(current);
  return result;
}

function renderSalesKPIs(data) {
  const totalFacturas = data.reduce((s, d) => s + d.valor, 0);
  const totalDomicilios = data.reduce((s, d) => s + d.domicilio, 0);
  const totalGeneral = totalFacturas + totalDomicilios;
  const numFacturas = data.length;

  const debe = data.filter(d =>
    d.pagoRealizado.toLowerCase() === "debe" ||
    d.cuenta.toLowerCase() === "debe" ||
    d.observaciones.toLowerCase() === "debe"
  );
  const totalDebe = debe.reduce((s, d) => s + d.valor + d.domicilio, 0);

  document.getElementById("kpi-total").textContent = "$" + totalGeneral.toLocaleString("es-CO");
  document.getElementById("kpi-facturas").textContent = numFacturas;
  document.getElementById("kpi-domicilios").textContent = "$" + totalDomicilios.toLocaleString("es-CO");
  document.getElementById("kpi-debe").textContent = "$" + totalDebe.toLocaleString("es-CO") + " (" + debe.length + ")";
}

function renderMonthlyChart(data) {
  const monthly = {};
  data.forEach(d => {
    const key = monthLabel(d.fecha);
    if (!monthly[key]) monthly[key] = { valor: 0, domicilio: 0 };
    monthly[key].valor += d.valor;
    monthly[key].domicilio += d.domicilio;
  });

  const sortedKeys = Object.keys(monthly).sort((a, b) => {
    const [ma, ya] = a.split(" ");
    const [mb, yb] = b.split(" ");
    const meses = ["Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dic"];
    return (parseInt(ya) - parseInt(yb)) || (meses.indexOf(ma) - meses.indexOf(mb));
  });

  const labels = sortedKeys;
  const valoresData = sortedKeys.map(k => monthly[k].valor);
  const domiciliosData = sortedKeys.map(k => monthly[k].domicilio);

  const ctx = document.getElementById("chart-ventas-mensuales").getContext("2d");
  if (ventasChart) ventasChart.destroy();

  ventasChart = new Chart(ctx, {
    type: "bar",
    data: {
      labels,
      datasets: [
        {
          label: "Valor facturas",
          data: valoresData,
          backgroundColor: "#c88a3d",
          borderRadius: 6,
        },
        {
          label: "Domicilios",
          data: domiciliosData,
          backgroundColor: "#a3b898",
          borderRadius: 6,
        },
      ],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { position: "top", labels: { color: "#6b5a4a", font: { family: "Inter" } } },
        tooltip: {
          callbacks: {
            label: (c) => c.dataset.label + ": $" + c.raw.toLocaleString("es-CO"),
          },
        },
      },
      scales: {
        x: {
          ticks: { color: "#8c7b6b", font: { family: "Inter", size: 11 } },
          grid: { display: false },
          title: { display: true, text: "Mes", color: "#6b5a4a", font: { family: "Inter", weight: "600" } },
        },
        y: {
          ticks: {
            color: "#8c7b6b",
            font: { family: "Inter", size: 11 },
            callback: (v) => "$" + (v / 1000000).toFixed(1) + "M",
          },
          grid: { color: "#e0d6c8" },
          title: { display: true, text: "Pesos COP", color: "#6b5a4a", font: { family: "Inter", weight: "600" } },
        },
      },
    },
  });
}

function renderTopClientesChart(data) {
  const clientes = {};
  data.forEach(d => {
    const total = d.valor + d.domicilio;
    if (!clientes[d.nombre]) clientes[d.nombre] = 0;
    clientes[d.nombre] += total;
  });

  const sorted = Object.entries(clientes)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10);

  const labels = sorted.map(s => s[0]);
  const valores = sorted.map(s => s[1]);

  const ctx = document.getElementById("chart-top-clientes").getContext("2d");
  if (clientesChart) clientesChart.destroy();

  clientesChart = new Chart(ctx, {
    type: "bar",
    data: {
      labels,
      datasets: [{
        label: "Total facturado",
        data: valores,
        backgroundColor: valores.map((_, i) => {
          const colors = ["#c88a3d", "#b03a2e", "#e39a2a", "#d68910", "#5b3a29",
                          "#7a9e7a", "#8b4513", "#f1c40f", "#a07c52", "#c9685e"];
          return colors[i] || "#c88a3d";
        }),
        borderRadius: 6,
      }],
    },
    options: {
      indexAxis: "y",
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: (c) => "$" + c.raw.toLocaleString("es-CO"),
          },
        },
      },
      scales: {
        x: {
          ticks: {
            color: "#8c7b6b",
            font: { family: "Inter", size: 11 },
            callback: (v) => "$" + (v / 1000000).toFixed(1) + "M",
          },
          grid: { color: "#e0d6c8" },
          title: { display: true, text: "Pesos COP", color: "#6b5a4a", font: { family: "Inter", weight: "600" } },
        },
        y: {
          ticks: { color: "#6b5a4a", font: { family: "Inter", size: 10 } },
          grid: { display: false },
          title: { display: true, text: "Cliente", color: "#6b5a4a", font: { family: "Inter", weight: "600" } },
        },
      },
    },
  });
}

function renderLastUpdate() {
  const now = new Date();
  document.getElementById("ventas-update").textContent =
    "Actualizado: " + now.toLocaleString("es-CO", { dateStyle: "short", timeStyle: "short" });
}

async function actualizarVentas() {
  const data = await fetchSalesData();
  if (!data || data.length === 0) {
    document.getElementById("ventas-status").textContent = "Sin datos disponibles.";
    return;
  }

  document.getElementById("ventas-status").textContent = data.length + " facturas cargadas";
  renderSalesKPIs(data);
  renderMonthlyChart(data);
  renderTopClientesChart(data);
  renderLastUpdate();

  document.getElementById("ventas-section").style.display = "block";
  document.getElementById("ventas-empty").style.display = "none";
}

// Auto-load on page init if ventas section exists
document.addEventListener("DOMContentLoaded", () => {
  const btn = document.getElementById("btn-actualizar-ventas");
  if (btn) {
    btn.addEventListener("click", actualizarVentas);
  }
});

import { Controller } from "@hotwired/stimulus";
import { Chart, registerables } from "chart.js";

Chart.register(...registerables);

function formatLabel(total, label, value) {
  const percentage = total !== 0 ? ((value / total) * 100).toFixed(1) : '0';
  const formatted = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0
  }).format(value);
  return `${label}: ${formatted} (${percentage}%)`;
}

export default class extends Controller {
  connect() {
    const ctx = this.element.getContext('2d');
    // Server sends top 9 vendors + "Others" (pre-aggregated), so chart matches table total
    const chartData = JSON.parse(this.element.dataset.chartData);
    const total = chartData.reduce((sum, item) => sum + item.value, 0);
    console.debug('[Vendor pie chart] slices=', chartData.length, 'total=$', total);
    chartData.forEach((item, i) => {
      console.debug(`  [${i}] vendor=${item.label} amount=$${item.value}`);
    });

    const labelPlugin = {
      id: 'alwaysShowLabels',
      afterDraw(chart) {
        const { ctx, data } = chart;
        const total = data.datasets[0].data.reduce((a, b) => a + b, 0);
        if (!chart.getDatasetMeta(0)?.data?.length) return;
        const chartArea = chart.chartArea;
        const padding = 10;
        const gap = 14; // gap between pie edge and label
        const fontSize = 14;
        ctx.font = `${fontSize}px sans-serif`;

        chart.getDatasetMeta(0).data.forEach((arc, i) => {
          const label = data.labels?.[i] ?? '';
          const value = data.datasets[0].data[i];
          const text = formatLabel(total, label, value);
          const midAngle = (arc.startAngle + arc.endAngle) / 2;
          const cos = Math.cos(midAngle);
          const sin = Math.sin(midAngle);

          // Point on the outer edge of the slice (line starts here)
          const sliceOuterX = arc.x + cos * arc.outerRadius;
          const sliceOuterY = arc.y + sin * arc.outerRadius;

          const textWidth = ctx.measureText(text).width;
          const textMargin = 8;
          const halfHeight = fontSize / 2;

          // Max distance from center so the full label stays inside chart area.
          // Label anchor is at (arc.x + cos*d, arc.y + sin*d); text extends by textWidth and halfHeight.
          const tMaxCandidates = [];
          if (cos > 1e-6) {
            tMaxCandidates.push((chartArea.right - padding - textWidth - textMargin - arc.x) / cos);
          } else if (cos < -1e-6) {
            tMaxCandidates.push((chartArea.left + padding + textWidth + textMargin - arc.x) / cos);
          }
          if (sin > 1e-6) {
            tMaxCandidates.push((chartArea.bottom - padding - halfHeight - arc.y) / sin);
          } else if (sin < -1e-6) {
            tMaxCandidates.push((chartArea.top + padding + halfHeight - arc.y) / sin);
          }
          const maxAllowed = tMaxCandidates.length > 0 ? Math.min(...tMaxCandidates.filter(t => t > 0)) : arc.outerRadius + gap;

          // Prefer just outside the pie; if that would go outside visible area, bring label in so it fits (line shortens). If there's room further out, we could use it for clarity but we keep it simple.
          const labelDist = Math.min(arc.outerRadius + gap, maxAllowed);

          const labelX = arc.x + cos * labelDist;
          const labelY = arc.y + sin * labelDist;
          const textX = labelX + (cos >= 0 ? 4 : -4);

          ctx.save();
          ctx.textBaseline = 'middle';
          ctx.textAlign = cos >= 0 ? 'left' : 'right';
          ctx.fillStyle = '#1f2937';

          // Leader line from slice edge to label (length varies so label stays visible)
          ctx.beginPath();
          ctx.moveTo(sliceOuterX, sliceOuterY);
          ctx.lineTo(labelX, labelY);
          ctx.strokeStyle = 'rgba(0,0,0,0.2)';
          ctx.lineWidth = 1;
          ctx.stroke();

          ctx.fillText(text, textX, labelY);
          ctx.restore();
        });
      }
    };

    new Chart(ctx, {
      type: 'pie',
      data: {
        labels: chartData.map(item => item.label),
        datasets: [{
          data: chartData.map(item => item.value),
          backgroundColor: [
            '#3B82F6', '#EF4444', '#10B981', '#F59E0B', '#6366F1',
            '#EC4899', '#8B5CF6', '#14B8A6', '#F97316', '#06B6D4',
            '#6B7280' // for Others
          ]
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: { enabled: false }
        },
      },
      plugins: [labelPlugin]
    });
  }
} 
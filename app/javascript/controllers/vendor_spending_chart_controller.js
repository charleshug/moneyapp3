import { Controller } from "@hotwired/stimulus";
import { Chart, registerables } from "chart.js";

Chart.register(...registerables);

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
          legend: {
            position: 'right',
            labels: {
              boxWidth: 12
            }
          },
          tooltip: {
            callbacks: {
              label: (context) => {
                const label = context.label || '';
                const value = context.raw;
                const percentage = total !== 0 ? ((value / total) * 100).toFixed(1) : '0';
                return `${label}: ${new Intl.NumberFormat('en-US', {
                  style: 'currency',
                  currency: 'USD',
                  maximumFractionDigits: 0
                }).format(value)} (${percentage}%)`;
              }
            }
          }
        }
      }
    });
  }
} 
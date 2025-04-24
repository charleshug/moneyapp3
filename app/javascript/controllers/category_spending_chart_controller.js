import { Controller } from "@hotwired/stimulus";
import { Chart, registerables } from "chart.js";

Chart.register(...registerables);

export default class extends Controller {
  connect() {
    const ctx = this.element.getContext('2d');
    const rawData = JSON.parse(this.element.dataset.chartData);
    
    // Sort data by value in descending order
    const sortedData = rawData.sort((a, b) => b.value - a.value);

    new Chart(ctx, {
      type: 'pie',
      data: {
        labels: sortedData.map(item => item.label),
        datasets: [{
          data: sortedData.map(item => item.value),
          backgroundColor: [
            '#3B82F6', '#EF4444', '#10B981', '#F59E0B', '#6366F1',
            '#EC4899', '#8B5CF6', '#14B8A6', '#F97316', '#06B6D4'
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
                const percentage = ((value / rawData.reduce((sum, item) => sum + item.value, 0)) * 100).toFixed(1);
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
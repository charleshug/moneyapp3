import { Controller } from "@hotwired/stimulus";
import { Chart, registerables } from "chart.js";

Chart.register(...registerables);

export default class extends Controller {
  connect() {
    console.log("Net Worth Chart Controller connected");
    const ctx = this.element.getContext('2d');
    const data = JSON.parse(this.element.dataset.chartData);

    new Chart(ctx, {
      type: 'line',
      data: {
        datasets: [{
          label: 'Net Worth',
          data: data,
          borderColor: 'rgb(59, 130, 246)',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          tension: 0.1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            type: 'linear',  // specifying the scale type
            ticks: {
              callback: (value) => {
                // Round the value to the nearest whole number
                const roundedValue = Math.round(value);
                // Format as currency without decimals
                return new Intl.NumberFormat('en-US', {
                  style: 'currency',
                  currency: 'USD',
                  maximumFractionDigits: 0  // Ensure no decimals are displayed
                }).format(roundedValue);
              },
              stepSize: 5000  // Set step size to $10,000
            }
          }
        },
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            callbacks: {
              label: (context) => {
                // Round and format tooltip values
                return new Intl.NumberFormat('en-US', {
                  style: 'currency',
                  currency: 'USD',
                  maximumFractionDigits: 0
                }).format(Math.round(context.parsed.y));
              }
            }
          }
        }
      }
    });
  }
}

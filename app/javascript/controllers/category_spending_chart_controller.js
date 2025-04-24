import { Controller } from "@hotwired/stimulus";
import { Chart, registerables } from "chart.js";

Chart.register(...registerables);

export default class extends Controller {
  connect() {
    this.rawData = JSON.parse(this.element.dataset.chartData);
    this.currentChart = null;
    this.showCategories();
  }

  showCategories() {
    if (this.currentChart) {
      this.currentChart.destroy();
    }
    
    const sortedData = this.rawData.sort((a, b) => b.value - a.value);
    this.renderChart('Spending by Category', sortedData, true);
  }

  showSubcategories(categoryData) {
    if (this.currentChart) {
      this.currentChart.destroy();
    }

    const subcategoryData = Object.entries(categoryData.subcategories)
      .map(([id, amount]) => ({
        label: document.querySelector(`[data-subcategory-id="${id}"]`)?.textContent.trim() || 'N/A',
        value: amount / 100.0
      }))
      .sort((a, b) => b.value - a.value);

    this.renderChart(
      `${categoryData.label} - Subcategories`,
      subcategoryData,
      false
    );
  }

  renderChart(title, data, isCategory) {
    const ctx = this.element.getContext('2d');
    
    this.currentChart = new Chart(ctx, {
      type: 'pie',
      data: {
        labels: data.map(item => item.label),
        datasets: [{
          data: data.map(item => item.value),
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
          title: {
            display: true,
            text: title,
            font: {
              size: 16,
              weight: 'bold'
            },
            padding: {
              bottom: 15
            }
          },
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
                const total = data.reduce((sum, item) => sum + item.value, 0);
                const percentage = ((value / total) * 100).toFixed(1);
                return `${label}: ${new Intl.NumberFormat('en-US', {
                  style: 'currency',
                  currency: 'USD',
                  maximumFractionDigits: 0
                }).format(value)} (${percentage}%)`;
              }
            }
          }
        },
        onClick: (event, elements) => {
          if (isCategory && elements.length > 0) {
            const index = elements[0].index;
            this.showSubcategories(this.rawData[index]);
          }
        }
      }
    });

    // Add back button if showing subcategories
    if (!isCategory) {
      this.addBackButton();
    }
  }

  addBackButton() {
    const container = this.element.parentElement;
    
    // Remove existing back button if any
    const existingButton = container.querySelector('.chart-back-button');
    if (existingButton) {
      existingButton.remove();
    }

    const button = document.createElement('button');
    button.className = 'chart-back-button absolute top-4 left-4 px-3 py-1 text-sm bg-gray-100 hover:bg-gray-200 rounded-md flex items-center gap-1';
    button.innerHTML = '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg> Back';
    button.addEventListener('click', () => {
      button.remove();
      this.showCategories();
    });

    container.appendChild(button);
  }
} 
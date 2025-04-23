import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("sidebar controller connected")
    this.setupSidebarToggle();
    this.setupReportsCollapsible();
  }

  setupSidebarToggle() {
    const toggleButton = document.getElementById('sidebar-toggle');
    const closeButton = document.getElementById('sidebar-close');
    const sidebar = document.getElementById('sidebar');
    const backdrop = document.getElementById('sidebar-backdrop');

    if (toggleButton && sidebar && backdrop) {
      toggleButton.addEventListener('click', () => {
        sidebar.classList.toggle('-translate-x-full');
        backdrop.classList.toggle('opacity-0');
        backdrop.classList.toggle('pointer-events-none');
        backdrop.classList.toggle('opacity-50');
      });
    }

    if (closeButton && sidebar && backdrop) {
      closeButton.addEventListener('click', () => {
        sidebar.classList.add('-translate-x-full');
        backdrop.classList.add('opacity-0');
        backdrop.classList.add('pointer-events-none');
        backdrop.classList.remove('opacity-50');
      });
    }

    if (backdrop && sidebar) {
      backdrop.addEventListener('click', () => {
        sidebar.classList.add('-translate-x-full');
        backdrop.classList.add('opacity-0');
        backdrop.classList.add('pointer-events-none');
        backdrop.classList.remove('opacity-50');
      });
    }
  }

  setupReportsCollapsible() {
    const reportsToggle = document.getElementById('reports-toggle');
    const reportsSubmenu = document.getElementById('reports-submenu');
    const reportsArrow = document.getElementById('reports-arrow');
    
    if (reportsToggle && reportsSubmenu && reportsArrow) {
      // Check if we're on a reports page and auto-expand if so
      const isReportsPage = window.location.pathname.startsWith('/reports');
      if (isReportsPage) {
        reportsSubmenu.classList.remove('hidden');
        reportsArrow.classList.add('rotate-180');
      }
      
      reportsToggle.addEventListener('click', () => {
        reportsSubmenu.classList.toggle('hidden');
        reportsArrow.classList.toggle('rotate-180');
      });
    }
  }
} 
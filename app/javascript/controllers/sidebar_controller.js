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

    if (toggleButton && sidebar) {
      toggleButton.addEventListener('click', () => {
        // Only toggle on mobile screens (below lg breakpoint)
        if (window.innerWidth < 1024) {
          sidebar.classList.toggle('-translate-x-full');
          if (backdrop) {
            backdrop.classList.toggle('opacity-0');
            backdrop.classList.toggle('pointer-events-none');
            backdrop.classList.toggle('opacity-50');
          }
        }
      });
    }

    if (closeButton && sidebar) {
      closeButton.addEventListener('click', () => {
        // Only close on mobile screens (below lg breakpoint)
        if (window.innerWidth < 1024) {
          sidebar.classList.add('-translate-x-full');
          if (backdrop) {
            backdrop.classList.add('opacity-0');
            backdrop.classList.add('pointer-events-none');
            backdrop.classList.remove('opacity-50');
          }
        }
      });
    }

    if (backdrop && sidebar) {
      backdrop.addEventListener('click', () => {
        // Only close on mobile screens (below lg breakpoint)
        if (window.innerWidth < 1024) {
          sidebar.classList.add('-translate-x-full');
          backdrop.classList.add('opacity-0');
          backdrop.classList.add('pointer-events-none');
          backdrop.classList.remove('opacity-50');
        }
      });
    }

    // Handle window resize to ensure sidebar state is correct
    window.addEventListener('resize', () => {
      if (window.innerWidth >= 1024) {
        // On desktop, ensure sidebar is visible (CSS handles this with lg:translate-x-0)
        if (backdrop) {
          backdrop.classList.add('opacity-0');
          backdrop.classList.add('pointer-events-none');
          backdrop.classList.remove('opacity-50');
        }
      } else {
        // On mobile, ensure sidebar is hidden by default
        sidebar.classList.add('-translate-x-full');
        if (backdrop) {
          backdrop.classList.add('opacity-0');
          backdrop.classList.add('pointer-events-none');
          backdrop.classList.remove('opacity-50');
        }
      }
    });
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
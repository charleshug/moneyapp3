import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.setupFilterSidebar();
  }

  setupFilterSidebar() {
    const filterToggle = document.getElementById('filter-toggle');
    const filterClose = document.getElementById('filter-close');
    const filterSidebar = document.getElementById('filter-sidebar');
    const filterBackdrop = document.getElementById('filter-backdrop');
    
    if (filterToggle && filterSidebar && filterBackdrop) {
      filterToggle.addEventListener('click', () => {
        filterSidebar.classList.toggle('-translate-x-full');
        filterBackdrop.classList.toggle('opacity-0');
        filterBackdrop.classList.toggle('pointer-events-none');
        filterBackdrop.classList.toggle('opacity-50');
      });
    }

    if (filterClose && filterSidebar && filterBackdrop) {
      filterClose.addEventListener('click', () => {
        filterSidebar.classList.add('-translate-x-full');
        filterBackdrop.classList.add('opacity-0');
        filterBackdrop.classList.add('pointer-events-none');
        filterBackdrop.classList.remove('opacity-50');
      });
    }

    if (filterBackdrop && filterSidebar) {
      filterBackdrop.addEventListener('click', () => {
        filterSidebar.classList.add('-translate-x-full');
        filterBackdrop.classList.add('opacity-0');
        filterBackdrop.classList.add('pointer-events-none');
        filterBackdrop.classList.remove('opacity-50');
      });
    }
  }
} 
// Bill Splitter Application
class BillSplitter {
    constructor() {
        this.persons = [];
        this.items = [];
        this.subtotal = 0;
        this.tax = 0;
        this.tip = 0;
        this.nextPersonId = 1;
        this.nextItemId = 1;
        this.subtotalManuallyOverridden = false; // Track if user has manually overridden subtotal
        this.draggedItemId = null; // Track which item is being dragged
        this.draggedPersonId = null; // Track which person is being dragged
        this.touchStartY = null; // Track touch start position for mobile
        this.touchElement = null; // Track element being dragged on touch
        this.currentPersonResults = null; // Store current results for receipt generation
        
        this.init();
    }

    init() {
        // Create default person
        this.addPerson('Person 1');
        
        // Create default empty item
        this.addItem();
        
        // Set up event listeners
        const addPersonBtn = document.getElementById('addPersonBtn');
        const addItemBtn = document.getElementById('addItemBtn');
        const calculateBtn = document.getElementById('calculateBtn');
        
        if (addPersonBtn) {
            addPersonBtn.addEventListener('click', () => this.handleAddPerson());
        }
        if (addItemBtn) {
            addItemBtn.addEventListener('click', () => this.handleAddItem());
        }
        if (calculateBtn) {
            calculateBtn.addEventListener('click', () => this.calculate());
        }
        
        // Subtotal input listener - update derived rates when subtotal is manually changed
        // Mark that user has manually overridden the subtotal
        const subtotalInput = document.getElementById('subtotal');
        let subtotalInputTimeout;
        if (subtotalInput) {
            subtotalInput.addEventListener('input', () => {
            // Clear any pending timeout
            if (subtotalInputTimeout) {
                clearTimeout(subtotalInputTimeout);
            }
            
                // Mark as manually overridden after a short delay (to distinguish from programmatic updates)
                subtotalInputTimeout = setTimeout(() => {
                    const enteredSubtotal = parseFloat(subtotalInput.value) || 0;
                const itemsTotal = this.items.filter(item => !item.isPlug).reduce((sum, item) => sum + item.price, 0);
                
                // If user manually changes subtotal to something different from items total, mark as overridden
                if (Math.abs(enteredSubtotal - itemsTotal) > 0.01) {
                    this.subtotalManuallyOverridden = true;
                }
            }, 100);
            
                this.updateTaxRateFromAmount();
                this.updateTipRateFromAmount();
                this.updateSubtotalDifference();
            });
        }
        
        // Tax amount input - update rate on blur
        const taxInput = document.getElementById('tax');
        if (taxInput) {
            taxInput.addEventListener('blur', () => this.updateTaxRateFromAmount());
        }
        
        // Tax rate input - update amount on blur
        const taxRateInput = document.getElementById('taxRate');
        if (taxRateInput) {
            taxRateInput.addEventListener('blur', () => this.updateTaxAmountFromRate());
        }
        
        // Tip amount input - update rate on blur
        const tipInput = document.getElementById('tip');
        if (tipInput) {
            tipInput.addEventListener('blur', () => this.updateTipRateFromAmount());
        }
        
        // Tip rate input - update amount on blur
        const tipRateInput = document.getElementById('tipRate');
        if (tipRateInput) {
            tipRateInput.addEventListener('blur', () => this.updateTipAmountFromRate());
        }
        
        // Render initial state
        this.renderPersons();
        this.renderItems();
        
        // Initialize subtotal from items (if any)
        this.updateItemsTotal();
        
        // Print receipt button
        const printReceiptBtn = document.getElementById('printReceiptBtn');
        if (printReceiptBtn) {
            printReceiptBtn.addEventListener('click', (e) => {
                e.preventDefault();
                e.stopPropagation();
                this.printReceipt();
            });
        }
    }

    // Person Management
    addPerson(name = '') {
        const person = {
            id: this.nextPersonId++,
            name: name || `Person ${this.nextPersonId - 1}`
        };
        this.persons.push(person);
        this.renderPersons();
        this.renderItems(); // Re-render items to update person checkboxes
        
        // Focus the newly added person's input field
        setTimeout(() => {
            const input = document.querySelector(`input[data-person-id="${person.id}"]`);
            if (input) {
                input.focus();
                input.select();
            }
        }, 0);
        
        return person;
    }

    removePerson(personId) {
        if (this.persons.length <= 1) {
            alert('Cannot remove the last person. At least one person is required.');
            return;
        }
        
        this.persons = this.persons.filter(p => p.id !== personId);
        
        // Remove person from all item assignments
        this.items.forEach(item => {
            item.assignedPersons = item.assignedPersons.filter(id => id !== personId);
        });
        
        this.renderPersons();
        this.renderItems();
    }

    updatePersonName(personId, name) {
        const person = this.persons.find(p => p.id === personId);
        if (person) {
            person.name = name;
        }
    }

    renderPersons() {
        const container = document.getElementById('personsList');
        container.innerHTML = '';
        
        this.persons.forEach((person, personIndex) => {
            const personDiv = document.createElement('div');
            personDiv.className = 'person-item';
            personDiv.dataset.personId = person.id;
            
            const dragHandle = '<div class="drag-handle" title="Drag to reorder">☰</div>';
            
            const baseTabIndex = 100 + (personIndex * 2); // Start at 100, increment by 2 for each person
            
            personDiv.innerHTML = `
                <div class="drag-handle-container">${dragHandle}</div>
                <input type="text" value="${this.escapeHtml(person.name)}" 
                       data-person-id="${person.id}"
                       placeholder="Person name"
                       tabindex="${baseTabIndex}">
                <button type="button" onclick="billSplitter.removePerson(${person.id})" tabindex="${baseTabIndex + 1}" autofocus="false">Remove</button>
            `;
            
            const input = personDiv.querySelector('input');
            
            // Update name on blur (when focus moves away)
            // Use a delayed re-render to avoid breaking tab order
            input.addEventListener('blur', (e) => {
                this.updatePersonName(person.id, e.target.value);
                // Only re-render items to update person names in checkboxes
                // Don't re-render persons immediately - it breaks tabbing
                // Use setTimeout to delay any person re-render until after tabbing is complete
                setTimeout(() => {
                    this.renderItems(); // Update items to reflect name changes in checkboxes
                }, 0);
            });
            
            // Drag and drop event listeners
            // Make only the drag handle draggable
            const dragHandleElement = personDiv.querySelector('.drag-handle');
            if (dragHandleElement) {
                dragHandleElement.draggable = true;
                
                // Desktop drag events
                dragHandleElement.addEventListener('dragstart', (e) => {
                    e.dataTransfer.effectAllowed = 'move';
                    e.dataTransfer.setData('text/plain', person.id.toString());
                    personDiv.classList.add('dragging');
                    this.draggedPersonId = person.id;
                });
                
                dragHandleElement.addEventListener('dragend', (e) => {
                    personDiv.classList.remove('dragging');
                    document.querySelectorAll('.person-item').forEach(item => {
                        item.classList.remove('drag-over');
                    });
                    this.draggedPersonId = null;
                });
                
                // Mobile touch events
                dragHandleElement.addEventListener('touchstart', (e) => {
                    e.preventDefault();
                    this.touchStartY = e.touches[0].clientY;
                    this.touchElement = personDiv;
                    personDiv.classList.add('dragging');
                    this.draggedPersonId = person.id;
                }, { passive: false });
            }
            
            // Drop zone is still the entire row
            personDiv.addEventListener('dragover', (e) => {
                e.preventDefault();
                e.dataTransfer.dropEffect = 'move';
                personDiv.classList.add('drag-over');
            });
            
            personDiv.addEventListener('dragleave', (e) => {
                personDiv.classList.remove('drag-over');
            });
            
            personDiv.addEventListener('drop', (e) => {
                e.preventDefault();
                personDiv.classList.remove('drag-over');
                
                if (!this.draggedPersonId) return;
                
                const draggedPersonId = this.draggedPersonId;
                const targetPersonId = parseInt(personDiv.dataset.personId);
                
                if (draggedPersonId === targetPersonId) return;
                
                this.reorderPersons(draggedPersonId, targetPersonId);
            });
            
            // Mobile touch move and end
            personDiv.addEventListener('touchmove', (e) => {
                if (!this.touchElement || this.touchElement !== personDiv) return;
                e.preventDefault();
                
                const touchY = e.touches[0].clientY;
                const allPersonItems = Array.from(document.querySelectorAll('.person-item'));
                
                // Find the person item under the touch point
                allPersonItems.forEach(item => {
                    const rect = item.getBoundingClientRect();
                    if (touchY >= rect.top && touchY <= rect.bottom) {
                        item.classList.add('drag-over');
                    } else {
                        item.classList.remove('drag-over');
                    }
                });
            }, { passive: false });
            
            personDiv.addEventListener('touchend', (e) => {
                if (!this.touchElement || this.touchElement !== personDiv) return;
                e.preventDefault();
                
                const touchY = e.changedTouches[0].clientY;
                const allPersonItems = Array.from(document.querySelectorAll('.person-item'));
                
                // Find the person item at the touch end position
                let targetPersonDiv = null;
                allPersonItems.forEach(item => {
                    item.classList.remove('drag-over');
                    const rect = item.getBoundingClientRect();
                    if (touchY >= rect.top && touchY <= rect.bottom) {
                        targetPersonDiv = item;
                    }
                });
                
                personDiv.classList.remove('dragging');
                
                if (targetPersonDiv && this.draggedPersonId) {
                    const draggedPersonId = this.draggedPersonId;
                    const targetPersonId = parseInt(targetPersonDiv.dataset.personId);
                    
                    if (draggedPersonId !== targetPersonId) {
                        this.reorderPersons(draggedPersonId, targetPersonId);
                    }
                }
                
                this.draggedPersonId = null;
                this.touchElement = null;
                this.touchStartY = null;
            });
            
            container.appendChild(personDiv);
        });
    }

    reorderPersons(draggedPersonId, targetPersonId) {
        const draggedIndex = this.persons.findIndex(p => p.id === draggedPersonId);
        const targetIndex = this.persons.findIndex(p => p.id === targetPersonId);
        
        if (draggedIndex === -1 || targetIndex === -1) return;
        
        // Remove dragged person from array
        const draggedPerson = this.persons.splice(draggedIndex, 1)[0];
        
        // Find new target index (may have shifted after removal)
        const newTargetIndex = this.persons.findIndex(p => p.id === targetPersonId);
        
        // Insert dragged person at target position
        this.persons.splice(newTargetIndex, 0, draggedPerson);
        
        // Re-render to reflect new order
        this.renderPersons();
        this.renderItems(); // Also update items to reflect new order in checkboxes
    }

    // Item Management
    addItem(itemData = {}) {
        const item = {
            id: this.nextItemId++,
            name: itemData.name || '',
            price: itemData.price || 0,
            taxable: itemData.taxable !== undefined ? itemData.taxable : true,
            tippable: itemData.tippable !== undefined ? itemData.tippable : true,
            memo: itemData.memo || '',
            assignedPersons: itemData.assignedPersons || [],
            isPlug: itemData.isPlug || false
        };
        this.items.push(item);
        this.renderItems();
        this.updateItemsTotal();
        return item;
    }

    removeItem(itemId) {
        this.items = this.items.filter(item => item.id !== itemId);
        this.renderItems();
        this.updateItemsTotal();
        this.updateSubtotalDifference(); // Update difference display
    }

    updateItem(itemId, field, value) {
        const item = this.items.find(i => i.id === itemId);
        if (item) {
            if (field === 'assignedPersons') {
                item.assignedPersons = value;
            } else {
                item[field] = value;
            }
            this.updateItemsTotal();
            this.updateSubtotalDifference(); // Update difference display
        }
    }

    handleAddItem() {
        const newItem = this.addItem();
        
        // Focus on the name field of the newly created item
        setTimeout(() => {
            const nameInput = document.querySelector(`input[data-item-id="${newItem.id}"][data-field="name"]`);
            if (nameInput) {
                nameInput.focus();
            }
        }, 0);
    }

    renderItems() {
        const container = document.getElementById('itemsList');
        container.innerHTML = '';
        
        // Separate plug items from regular items
        const regularItems = this.items.filter(item => !item.isPlug);
        const plugItems = this.items.filter(item => item.isPlug);
        
        // Render regular items first (preserve their order)
        regularItems.forEach(item => {
            this.renderItemRow(container, item);
        });
        
        // Render plug items last (preserve their order)
        plugItems.forEach(item => {
            this.renderItemRow(container, item);
        });
    }

    reorderItems(draggedItemId, targetItemId) {
        const draggedIndex = this.items.findIndex(item => item.id === draggedItemId);
        const targetIndex = this.items.findIndex(item => item.id === targetItemId);
        
        if (draggedIndex === -1 || targetIndex === -1) return;
        
        const draggedItem = this.items[draggedIndex];
        const targetItem = this.items[targetIndex];
        
        // Don't allow reordering between plug and regular items
        if (draggedItem.isPlug !== targetItem.isPlug) return;
        
        // Remove dragged item from array
        this.items.splice(draggedIndex, 1);
        
        // Find new target index (may have shifted after removal)
        const newTargetIndex = this.items.findIndex(item => item.id === targetItemId);
        
        // Insert dragged item at target position
        this.items.splice(newTargetIndex, 0, draggedItem);
        
        // Re-render to reflect new order
        this.renderItems();
    }

    renderItemRow(container, item) {
            const itemRow = document.createElement('div');
            itemRow.className = 'item-row' + (item.isPlug ? ' plug-item' : '') + 
                               (item.isPlug && item.price < 0 ? ' negative' : '');
            itemRow.dataset.itemId = item.id;
            
            // Calculate tabindex for items (start after persons section and Add Person button)
            // Each item has: name, price, taxable, tippable, memo, person checkboxes, remove button
            const regularItems = this.items.filter(i => !i.isPlug);
            const itemIndex = regularItems.findIndex(i => i.id === item.id);
            // Base fields per item: name(0), price(1), taxable(2), tippable(3), memo(4) = 5 fields
            // Then person checkboxes, then remove button
            // Calculate how many fields before this item: 5 fields per previous item + person checkboxes per previous item + 1 remove button
            let fieldsBeforeThisItem = 0;
            for (let i = 0; i < itemIndex; i++) {
                fieldsBeforeThisItem += 5; // name, price, taxable, tippable, memo
                fieldsBeforeThisItem += this.persons.length; // person checkboxes
                fieldsBeforeThisItem += 1; // remove button
            }
            // Start at 300 (after persons section which ends at ~200 for Add Person button)
            const baseItemTabIndex = 300 + fieldsBeforeThisItem;
            
            // Name column
            const nameInput = `<input type="text" value="${this.escapeHtml(item.name)}" 
                                     placeholder="Item name" 
                                     data-item-id="${item.id}" 
                                     data-field="name"
                                     tabindex="${baseItemTabIndex}">`;
            
            // Price column (allow negative for plug items)
            const minValue = item.isPlug ? '' : 'min="0"';
            const priceInput = `<input type="number" value="${item.price.toFixed(2)}" 
                                       step="0.01" ${minValue}
                                       data-item-id="${item.id}" 
                                       data-field="price"
                                       tabindex="${baseItemTabIndex + 1}">`;
            
            // Taxable checkbox
            const taxableCheck = `<input type="checkbox" ${item.taxable ? 'checked' : ''} 
                                          data-item-id="${item.id}" 
                                          data-field="taxable"
                                          tabindex="${baseItemTabIndex + 2}">`;
            
            // Tippable checkbox
            const tippableCheck = `<input type="checkbox" ${item.tippable ? 'checked' : ''} 
                                          data-item-id="${item.id}" 
                                          data-field="tippable"
                                          tabindex="${baseItemTabIndex + 3}">`;
            
            // Memo column
            const memoInput = `<input type="text" value="${this.escapeHtml(item.memo)}" 
                                     placeholder="Memo" 
                                     data-item-id="${item.id}" 
                                     data-field="memo"
                                     tabindex="${baseItemTabIndex + 4}">`;
            
            // Person assignments
            let personAssignments = '<div class="person-assignments">';
            this.persons.forEach((person, personIdx) => {
                const checked = item.assignedPersons.includes(person.id) ? 'checked' : '';
                personAssignments += `
                    <div class="person-checkbox">
                        <input type="checkbox" ${checked} 
                               data-item-id="${item.id}" 
                               data-person-id="${person.id}"
                               tabindex="${baseItemTabIndex + 5 + personIdx}">
                        <label>${this.escapeHtml(person.name)}</label>
                    </div>
                `;
            });
            personAssignments += '</div>';
            
            // Remove button (after all person checkboxes)
            const removeBtnTabIndex = baseItemTabIndex + 5 + this.persons.length;
            const removeBtn = `<button type="button" onclick="billSplitter.removeItem(${item.id})" tabindex="${removeBtnTabIndex}">Remove</button>`;
            
            // Plug item warning
            let plugWarning = '';
            if (item.isPlug) {
                const warningText = item.price < 0 
                    ? '⚠️ NEGATIVE PLUG ITEM - Items exceed subtotal!' 
                    : '⚠️ PLUG ITEM - Created to balance bill';
                plugWarning = `<div class="plug-warning">${warningText}</div>`;
            }
            
            // Drag handle icon
            const dragHandle = '<div class="drag-handle" title="Drag to reorder">☰</div>';
            
            itemRow.innerHTML = `
                <div class="drag-handle-container">${dragHandle}</div>
                <div class="item-main-content">
                    <div class="item-name-row">
                        <div class="item-name-field">${nameInput}</div>
                    </div>
                    <div class="item-price-row">
                        <div class="item-price-field">${priceInput}</div>
                    </div>
                    <div class="item-checkboxes-row">
                        <label class="checkbox-label">Taxable ${taxableCheck}</label>
                        <label class="checkbox-label">Tippable ${tippableCheck}</label>
                    </div>
                    <div class="item-persons-row">
                        ${personAssignments}
                    </div>
                    ${plugWarning}
                </div>
                <div class="item-actions">
                    ${removeBtn}
                </div>
            `;
            
            // Add event listeners
            itemRow.querySelectorAll('input[data-field]').forEach(input => {
                input.addEventListener('change', (e) => {
                    const field = e.target.dataset.field;
                    let value = e.target.value;
                    
                    if (field === 'price') {
                        value = parseFloat(value) || 0;
                    } else if (field === 'taxable' || field === 'tippable') {
                        value = e.target.checked;
                    } else if (field === 'memo') {
                        // Memo field removed, but keep for backward compatibility
                        return;
                    }
                    
                    this.updateItem(item.id, field, value);
                });
            });
            
            // Person assignment checkboxes
            itemRow.querySelectorAll('input[type="checkbox"][data-person-id]').forEach(checkbox => {
                checkbox.addEventListener('change', (e) => {
                    const personId = parseInt(e.target.dataset.personId);
                    const item = this.items.find(i => i.id === parseInt(e.target.dataset.itemId));
                    
                    if (e.target.checked) {
                        if (!item.assignedPersons.includes(personId)) {
                            item.assignedPersons.push(personId);
                        }
                    } else {
                        item.assignedPersons = item.assignedPersons.filter(id => id !== personId);
                    }
                });
            });
            
            // Drag and drop event listeners
            // Make only the drag handle draggable
            const dragHandleElement = itemRow.querySelector('.drag-handle');
            if (dragHandleElement) {
                dragHandleElement.draggable = true;
                
                // Desktop drag events
                dragHandleElement.addEventListener('dragstart', (e) => {
                    e.dataTransfer.effectAllowed = 'move';
                    e.dataTransfer.setData('text/html', itemRow.outerHTML);
                    e.dataTransfer.setData('text/plain', item.id.toString());
                    itemRow.classList.add('dragging');
                    this.draggedItemId = item.id;
                });
                
                dragHandleElement.addEventListener('dragend', (e) => {
                    itemRow.classList.remove('dragging');
                    document.querySelectorAll('.item-row').forEach(row => {
                        row.classList.remove('drag-over');
                    });
                    this.draggedItemId = null;
                });
                
                // Mobile touch events
                dragHandleElement.addEventListener('touchstart', (e) => {
                    e.preventDefault();
                    this.touchStartY = e.touches[0].clientY;
                    this.touchElement = itemRow;
                    itemRow.classList.add('dragging');
                    this.draggedItemId = item.id;
                }, { passive: false });
            }
            
            // Drop zone is still the entire row
            itemRow.addEventListener('dragover', (e) => {
                e.preventDefault();
                e.dataTransfer.dropEffect = 'move';
                
                const draggedItem = this.items.find(i => i.id === this.draggedItemId);
                const targetItem = this.items.find(i => i.id === parseInt(itemRow.dataset.itemId));
                
                // Don't allow dropping plug items on regular items or vice versa
                if (draggedItem && targetItem && draggedItem.isPlug !== targetItem.isPlug) {
                    return;
                }
                
                itemRow.classList.add('drag-over');
            });
            
            itemRow.addEventListener('dragleave', (e) => {
                itemRow.classList.remove('drag-over');
            });
            
            itemRow.addEventListener('drop', (e) => {
                e.preventDefault();
                itemRow.classList.remove('drag-over');
                
                if (!this.draggedItemId) return;
                
                const draggedItemId = this.draggedItemId;
                const targetItemId = parseInt(itemRow.dataset.itemId);
                
                if (draggedItemId === targetItemId) return;
                
                const draggedItem = this.items.find(i => i.id === draggedItemId);
                const targetItem = this.items.find(i => i.id === targetItemId);
                
                // Don't allow reordering between plug and regular items
                if (draggedItem.isPlug !== targetItem.isPlug) {
                    return;
                }
                
                this.reorderItems(draggedItemId, targetItemId);
            });
            
            // Mobile touch move and end
            itemRow.addEventListener('touchmove', (e) => {
                if (!this.touchElement || this.touchElement !== itemRow) return;
                e.preventDefault();
                
                const touchY = e.touches[0].clientY;
                const draggedItem = this.items.find(i => i.id === this.draggedItemId);
                const allItemRows = Array.from(document.querySelectorAll('.item-row'));
                
                // Find the item row under the touch point
                allItemRows.forEach(row => {
                    const targetItem = this.items.find(i => i.id === parseInt(row.dataset.itemId));
                    if (!targetItem || !draggedItem) return;
                    
                    // Don't allow dropping plug items on regular items or vice versa
                    if (draggedItem.isPlug !== targetItem.isPlug) {
                        row.classList.remove('drag-over');
                        return;
                    }
                    
                    const rect = row.getBoundingClientRect();
                    if (touchY >= rect.top && touchY <= rect.bottom) {
                        row.classList.add('drag-over');
                    } else {
                        row.classList.remove('drag-over');
                    }
                });
            }, { passive: false });
            
            itemRow.addEventListener('touchend', (e) => {
                if (!this.touchElement || this.touchElement !== itemRow) return;
                e.preventDefault();
                
                const touchY = e.changedTouches[0].clientY;
                const allItemRows = Array.from(document.querySelectorAll('.item-row'));
                
                // Find the item row at the touch end position
                let targetItemRow = null;
                allItemRows.forEach(row => {
                    row.classList.remove('drag-over');
                    const rect = row.getBoundingClientRect();
                    if (touchY >= rect.top && touchY <= rect.bottom) {
                        targetItemRow = row;
                    }
                });
                
                itemRow.classList.remove('dragging');
                
                if (targetItemRow && this.draggedItemId) {
                    const draggedItemId = this.draggedItemId;
                    const targetItemId = parseInt(targetItemRow.dataset.itemId);
                    const draggedItem = this.items.find(i => i.id === draggedItemId);
                    const targetItem = this.items.find(i => i.id === targetItemId);
                    
                    if (draggedItemId !== targetItemId && draggedItem && targetItem) {
                        // Don't allow reordering between plug and regular items
                        if (draggedItem.isPlug === targetItem.isPlug) {
                            this.reorderItems(draggedItemId, targetItemId);
                        }
                    }
                }
                
                this.draggedItemId = null;
                this.touchElement = null;
                this.touchStartY = null;
            });
            
            container.appendChild(itemRow);
    }

    updateItemsTotal() {
        const total = this.items.filter(item => !item.isPlug).reduce((sum, item) => sum + item.price, 0);
        document.getElementById('itemsTotal').textContent = total.toFixed(2);
        
        // Auto-update subtotal field with items total (if user hasn't manually overridden it)
        if (!this.subtotalManuallyOverridden) {
            const subtotalInput = document.getElementById('subtotal');
            const currentValue = parseFloat(subtotalInput.value) || 0;
            subtotalInput.value = total.toFixed(2);
            
            // Only update rates if value actually changed
            if (Math.abs(currentValue - total) > 0.01) {
                this.updateTaxRateFromAmount();
                this.updateTipRateFromAmount();
            }
        }
        
        this.updateSubtotalDifference();
    }

    // Subtotal Difference Display (doesn't create plug item, just shows difference)
    updateSubtotalDifference() {
        const subtotalInput = document.getElementById('subtotal');
        const enteredSubtotal = parseFloat(subtotalInput.value) || 0;
        
        const itemsTotal = this.items.filter(item => !item.isPlug).reduce((sum, item) => sum + item.price, 0);
        const difference = enteredSubtotal - itemsTotal;
        
        const differenceDiv = document.getElementById('subtotalDifference');
        
        if (enteredSubtotal > 0 && Math.abs(difference) > 0.01) {
            differenceDiv.textContent = `Difference: $${difference.toFixed(2)} ${difference < 0 ? '(items exceed subtotal!)' : '(plug item will be created on calculate)'}`;
            differenceDiv.className = 'difference ' + (difference < 0 ? 'warning' : '');
        } else {
            differenceDiv.textContent = '';
            differenceDiv.className = 'difference';
        }
    }

    // Total of taxable items (for tax rate derivation)
    getTaxableItemsTotal() {
        return this.items
            .filter(item => item.taxable)
            .reduce((sum, item) => sum + item.price, 0);
    }

    // Total of tippable items (for tip rate derivation)
    getTippableItemsTotal() {
        return this.items
            .filter(item => item.tippable)
            .reduce((sum, item) => sum + item.price, 0);
    }

    // Tax: Update rate field from amount (on amount blur)
    // Rate = specified tax / total of taxable items
    updateTaxRateFromAmount() {
        const taxInput = document.getElementById('tax');
        const taxAmount = parseFloat(taxInput.value) || 0;
        const taxableTotal = this.getTaxableItemsTotal();
        
        const rateInput = document.getElementById('taxRate');
        if (taxableTotal > 0 && taxAmount > 0) {
            const rate = (taxAmount / taxableTotal) * 100;
            rateInput.value = rate.toFixed(2);
        } else {
            rateInput.value = '';
        }
    }

    // Tax: Update amount field from rate (on rate blur)
    // Amount = (total of taxable items * rate) / 100
    updateTaxAmountFromRate() {
        const rateInput = document.getElementById('taxRate');
        const rate = parseFloat(rateInput.value) || 0;
        const taxableTotal = this.getTaxableItemsTotal();
        const taxInput = document.getElementById('tax');
        
        if (taxableTotal > 0 && rate > 0) {
            const calculatedTax = (taxableTotal * rate) / 100;
            taxInput.value = calculatedTax.toFixed(2);
            // Recalculate and display rate (in case of rounding)
            this.updateTaxRateFromAmount();
        }
    }

    // Tip: Update rate field from amount (on amount blur)
    // Rate = specified tip / total of tippable items
    updateTipRateFromAmount() {
        const tipInput = document.getElementById('tip');
        const tipAmount = parseFloat(tipInput.value) || 0;
        const tippableTotal = this.getTippableItemsTotal();
        
        const rateInput = document.getElementById('tipRate');
        if (tippableTotal > 0 && tipAmount > 0) {
            const rate = (tipAmount / tippableTotal) * 100;
            rateInput.value = rate.toFixed(2);
        } else {
            rateInput.value = '';
        }
    }

    // Tip: Update amount field from rate (on rate blur)
    // Amount = (total of tippable items * rate) / 100
    updateTipAmountFromRate() {
        const rateInput = document.getElementById('tipRate');
        const rate = parseFloat(rateInput.value) || 0;
        const tippableTotal = this.getTippableItemsTotal();
        const tipInput = document.getElementById('tip');
        
        if (tippableTotal > 0 && rate > 0) {
            const calculatedTip = (tippableTotal * rate) / 100;
            tipInput.value = calculatedTip.toFixed(2);
            // Recalculate and display rate (in case of rounding)
            this.updateTipRateFromAmount();
        }
    }

    // Calculation
    calculate() {
        const subtotalInput = document.getElementById('subtotal');
        const taxInput = document.getElementById('tax');
        const tipInput = document.getElementById('tip');
        
        this.subtotal = parseFloat(subtotalInput.value) || 0;
        this.tax = parseFloat(taxInput.value) || 0;
        
        // Calculate tip: amount takes precedence over rate
        const tipAmount = parseFloat(tipInput.value) || 0;
        
        if (tipAmount > 0) {
            // Use amount if provided
            this.tip = tipAmount;
        } else {
            // Check if tip rate is entered
            const tipRateInput = document.getElementById('tipRate');
            const tipRate = parseFloat(tipRateInput.value) || 0;
            const tippableTotal = this.getTippableItemsTotal();
            if (tipRate > 0 && tippableTotal > 0) {
                // Calculate from rate if amount is not provided (rate applies to tippable items total)
                this.tip = (tippableTotal * tipRate) / 100;
                tipInput.value = this.tip.toFixed(2);
            } else {
                this.tip = 0;
            }
        }
        
        // Update rates to reflect final values
        this.updateTaxRateFromAmount();
        this.updateTipRateFromAmount();
        
        if (this.persons.length === 0) {
            alert('Please add at least one person.');
            return;
        }
        
        // Create or update plug item based on subtotal
        this.updatePlugItem();
        
        if (this.items.length === 0) {
            alert('Please add at least one item.');
            return;
        }
        
        // Calculate tax and tip shares for each item
        const taxableTotal = this.items
            .filter(item => item.taxable)
            .reduce((sum, item) => sum + item.price, 0);
        
        const tippableTotal = this.items
            .filter(item => item.tippable)
            .reduce((sum, item) => sum + item.price, 0);
        
        // Calculate item totals (price + tax share + tip share)
        this.items.forEach(item => {
            item.taxShare = 0;
            item.tipShare = 0;
            
            if (item.taxable && taxableTotal > 0) {
                item.taxShare = (item.price / taxableTotal) * this.tax;
            }
            
            if (item.tippable && tippableTotal > 0) {
                item.tipShare = (item.price / tippableTotal) * this.tip;
            }
            
            item.total = item.price + item.taxShare + item.tipShare;
        });
        
        // Calculate person totals
        const personResults = this.persons.map(person => {
            const personItems = [];
            let personTotal = 0;
            
            this.items.forEach(item => {
                // Determine who this item is assigned to
                const assignedPersons = item.assignedPersons.length > 0 
                    ? item.assignedPersons 
                    : this.persons.map(p => p.id);
                
                if (assignedPersons.includes(person.id)) {
                    const share = item.total / assignedPersons.length;
                    const taxPortion = item.taxShare / assignedPersons.length;
                    const tipPortion = item.tipShare / assignedPersons.length;
                    
                    personTotal += share;
                    
                    personItems.push({
                        item: item,
                        share: share,
                        taxPortion: taxPortion,
                        tipPortion: tipPortion
                    });
                }
            });
            
            return {
                person: person,
                items: personItems,
                total: personTotal
            };
        });
        
        // Store results for receipt generation
        this.currentPersonResults = personResults;
        
        this.renderResults(personResults);
    }

    // Update plug item (only called on calculate)
    updatePlugItem() {
        const subtotalInput = document.getElementById('subtotal');
        const enteredSubtotal = parseFloat(subtotalInput.value) || 0;
        
        if (enteredSubtotal <= 0) {
            // Remove plug item if subtotal is cleared
            const plugItem = this.items.find(item => item.isPlug);
            if (plugItem) {
                this.removeItem(plugItem.id);
            }
            return;
        }
        
        const itemsTotal = this.items.filter(item => !item.isPlug).reduce((sum, item) => sum + item.price, 0);
        const difference = enteredSubtotal - itemsTotal;
        
        let plugItem = this.items.find(item => item.isPlug);
        
        if (Math.abs(difference) > 0.01) {
            // Create or update plug item
            if (plugItem) {
                plugItem.price = difference;
                // Re-render to ensure plug item appears last
                this.renderItems();
            } else {
                this.addItem({
                    name: 'plug',
                    price: difference,
                    memo: 'plug',
                    taxable: true,
                    tippable: true,
                    isPlug: true,
                    assignedPersons: []
                });
            }
        } else {
            // Remove plug item if difference is negligible
            if (plugItem) {
                this.removeItem(plugItem.id);
            }
        }
    }

    renderResults(personResults) {
        const section = document.getElementById('resultsSection');
        const content = document.getElementById('resultsContent');
        content.innerHTML = '';
        
        personResults.forEach(result => {
            const personDiv = document.createElement('div');
            personDiv.className = 'person-result';
            
            let itemsHtml = '<div class="person-items-list">';
            let subtotal = 0;
            let taxTotal = 0;
            let tipTotal = 0;
            
            result.items.forEach(itemDetail => {
                const item = itemDetail.item;
                subtotal += item.price / (item.assignedPersons.length > 0 ? item.assignedPersons.length : this.persons.length);
                taxTotal += itemDetail.taxPortion;
                tipTotal += itemDetail.tipPortion;
                
                itemsHtml += `
                    <div class="person-item-detail">
                        <div class="item-name">${this.escapeHtml(item.name || 'Unnamed item')}</div>
                        <div class="item-breakdown">
                            Price: $${item.price.toFixed(2)} | 
                            Tax: $${itemDetail.taxPortion.toFixed(2)} | 
                            Tip: $${itemDetail.tipPortion.toFixed(2)} | 
                            <strong>Share: $${itemDetail.share.toFixed(2)}</strong>
                        </div>
                    </div>
                `;
            });
            
            itemsHtml += '</div>';
            
            const totalsHtml = `
                <div class="person-totals">
                    <div><span>Subtotal:</span> <span>$${subtotal.toFixed(2)}</span></div>
                    <div><span>Tax:</span> <span>$${taxTotal.toFixed(2)}</span></div>
                    <div><span>Tip:</span> <span>$${tipTotal.toFixed(2)}</span></div>
                    <div class="total-owed">
                        <span>Total Owed:</span> <span>$${result.total.toFixed(2)}</span>
                    </div>
                </div>
            `;
            
            personDiv.innerHTML = `
                <h3>${this.escapeHtml(result.person.name)}</h3>
                ${itemsHtml}
                ${totalsHtml}
            `;
            
            content.appendChild(personDiv);
        });
        
        section.style.display = 'block';
    }

    // Utility
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    // Event Handlers
    handleAddPerson() {
        // Add person inline (similar to add item)
        this.addPerson();
    }

    // Print Receipt
    printReceipt() {
        if (!this.currentPersonResults || this.currentPersonResults.length === 0) {
            alert('Please calculate the bill first.');
            return;
        }

        const subtotalInput = document.getElementById('subtotal');
        const taxInput = document.getElementById('tax');
        const tipInput = document.getElementById('tip');
        
        const billSubtotal = parseFloat(subtotalInput.value) || 0;
        const billTax = parseFloat(taxInput.value) || 0;
        const billTip = parseFloat(tipInput.value) || 0;

        // Open receipt.html from the same directory as app.js
        // Files are in public/bill-splitter/ so use /bill-splitter/receipt.html
        const receiptPath = '/bill-splitter/receipt.html';
        const receiptWindow = window.open(receiptPath, '_blank');
        
        // Wait for the window to load before setting data
        if (receiptWindow) {
            receiptWindow.addEventListener('load', () => {
                receiptWindow.receiptData = {
                    items: this.items,
                    persons: this.persons,
                    results: this.currentPersonResults,
                    billSummary: {
                        subtotal: billSubtotal,
                        tax: billTax,
                        tip: billTip
                    }
                };
            });
        }
    }
}

// Initialize application
let billSplitter;
document.addEventListener('DOMContentLoaded', () => {
    billSplitter = new BillSplitter();
});

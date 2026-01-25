// Receipt rendering script
const root = document.getElementById('receipt-root');

function renderReceipt(data) {
    const {
        items,
        persons,
        results,
        billSummary
    } = data;

    root.innerHTML = `
        <div class="receipt-header">
            <h1>Restaurant Bill Receipt</h1>
            <p>${new Date().toLocaleString()}</p>
        </div>

        ${renderBillSummary(billSummary, items, persons)}
        ${results.map(renderPersonSection).join('')}
    `;
}

function renderBillSummary(billSummary, items, persons) {
    const { subtotal, tax, tip } = billSummary;
    const total = subtotal + tax + tip;

    // Generate items ordered HTML
    let itemsOrderedHtml = '';
    const regularItems = items.filter(item => !item.isPlug);
    regularItems.forEach(item => {
        const assignedPersonIds = item.assignedPersons.length > 0 
            ? item.assignedPersons 
            : persons.map(p => p.id);
        
        const assignedPeople = persons
            .filter(p => assignedPersonIds.includes(p.id))
            .map(p => p.name);
        
        const peopleList = assignedPeople.length > 0 
            ? assignedPeople.join(', ') 
            : 'Everyone';
        
        itemsOrderedHtml += `
            <div class="all-item-row">
                <div class="all-item-name">${escapeHtml(item.name || 'Unnamed item')}</div>
                <div class="all-item-price">Price: $${item.price.toFixed(2)}</div>
                <div class="all-item-people">
                    <span class="all-item-people-label">Assigned to:</span>
                    <span class="all-item-people-list">${escapeHtml(peopleList)}</span>
                </div>
            </div>`;
    });

    return `
        <div class="bill-summary">
            <h2>Bill Summary</h2>
            
            <div style="margin-bottom: 20px;">
                <h3 style="font-size: 16px; margin-bottom: 10px; color: #555;">Items Ordered</h3>
                ${itemsOrderedHtml}
            </div>
            
            <div style="margin-top: 20px; padding-top: 20px; border-top: 2px solid #ddd;">
                <h3 style="font-size: 16px; margin-bottom: 10px; color: #555;">Totals</h3>
                <div class="bill-summary-row">
                    <span>Subtotal:</span>
                    <span>$${subtotal.toFixed(2)}</span>
                </div>
                <div class="bill-summary-row">
                    <span>Tax:</span>
                    <span>$${tax.toFixed(2)}</span>
                </div>
                <div class="bill-summary-row">
                    <span>Tip:</span>
                    <span>$${tip.toFixed(2)}</span>
                </div>
                <div class="bill-summary-row">
                    <span>Total:</span>
                    <span>$${total.toFixed(2)}</span>
                </div>
            </div>
        </div>`;
}

function renderPersonSection(result) {
    const { person, items: itemDetails, total } = result;
    const persons = window.receiptData.persons;
    
    let personSubtotal = 0;
    let personTax = 0;
    let personTip = 0;

    let itemsHtml = '<div class="items-list">';
    itemDetails.forEach(itemDetail => {
        const item = itemDetail.item;
        personSubtotal += item.price / (item.assignedPersons.length > 0 ? item.assignedPersons.length : persons.length);
        personTax += itemDetail.taxPortion;
        personTip += itemDetail.tipPortion;

        itemsHtml += `
            <div class="item-row">
                <div class="item-name">${escapeHtml(item.name || 'Unnamed item')}</div>
                <div class="item-details">
                    Item Price: $${item.price.toFixed(2)} | 
                    Tax: $${itemDetail.taxPortion.toFixed(2)} | 
                    Tip: $${itemDetail.tipPortion.toFixed(2)} | 
                    <strong>Your Share: $${itemDetail.share.toFixed(2)}</strong>
                </div>
            </div>
        `;
    });
    itemsHtml += '</div>';

    return `
        <div class="person-section">
            <h3>${escapeHtml(person.name)}</h3>
            ${itemsHtml}
            <div class="person-totals">
                <div class="person-totals-row">
                    <span>Subtotal:</span>
                    <span>$${personSubtotal.toFixed(2)}</span>
                </div>
                <div class="person-totals-row">
                    <span>Tax:</span>
                    <span>$${personTax.toFixed(2)}</span>
                </div>
                <div class="person-totals-row">
                    <span>Tip:</span>
                    <span>$${personTip.toFixed(2)}</span>
                </div>
                <div class="person-totals-row total">
                    <span>Total Owed:</span>
                    <span>$${total.toFixed(2)}</span>
                </div>
            </div>
        </div>`;
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Wait for data to be set by parent window
function checkForData() {
    if (window.receiptData) {
        renderReceipt(window.receiptData);
    } else {
        // Check again after a short delay
        setTimeout(checkForData, 50);
    }
}

// Start checking for data
checkForData();

# Restaurant Bill Splitter & Tip Calculator - Implementation Plan

## Overview
A standalone JavaScript application for splitting restaurant bills among multiple people, with support for taxable/non-taxable items, tippable items, and flexible person assignments. Items can be assigned to specific persons or split among all persons.

---

## Core Features

### 1. Item Entry Form
- **Fields per item:**
  - Item name/description
  - Price (required, numeric)
  - Taxable checkbox (default: checked)
  - Tippable checkbox (default: checked)
  - Memo/notes (optional text field)
  - Person assignment (multi-select):
    - Checkboxes or multi-select dropdown for each person
    - "Add new Person" button/link
    - If no persons assigned: item splits among all persons on check
    - If persons assigned: item splits evenly among assigned persons only

- **UI Behavior:**
  - Add item button adds new item row
  - Remove item button per row
  - Edit item button (items are editable throughout)
  - Running subtotal display (sum of all item prices)
  - Form validation (price must be numeric, > 0)

### 2. Person Management
- **Person Creation:**
  - "Add Person" button/link
  - Input: Person name
  - Person added to list immediately
  - Person available for assignment on all items
  - Persons can be added/removed throughout the session

- **Person Removal:**
  - Remove button next to each person
  - If person is removed, items assigned to them revert to "all persons" (group)
  - Cannot remove person if they're the only person (must have at least one)

- **Default Person:**
  - If no persons are created, default to a single person (e.g., "Person 1")
  - This ensures items can always be split

### 3. Bill Totals Entry
- **Subtotal Field:**
  - User enters actual bill subtotal
  - Validation: Compare entered subtotal vs. sum of items
  - If mismatch: Auto-create "plug" item
    - Price = difference (subtotal - sum of items)
    - Memo = "plug"
    - Taxable = true (default)
    - Tippable = true (default)
    - Assignment = all persons (group split)
    - **Visual Treatment:**
      - If negative: Red background/text with warning message
      - If positive: Highlighted/obvious styling to make it clear it's a plug item
      - Always show warning/notice text explaining it's a plug item

- **Tax Field:**
  - User enters tax amount (dollar amount, not percentage)
  - Display derived tax rate: `(Tax / Subtotal) × 100%` in fainter text beside input
  - Tax is distributed proportionally among taxable items only
  - Each taxable item gets: `(item price / sum of taxable items) × total tax`

- **Tip Field:**
  - User enters tip amount (dollar amount, not percentage)
  - Tip is distributed proportionally among tippable items only
  - Each tippable item gets: `(item price / sum of tippable items) × total tip`

### 4. Calculation & Results Display
- **Calculate Button:**
  - Processes all items, tax, and tip
  - Calculates per-person totals
  - Displays results (can be shown inline or in separate section)

- **Calculation Logic:**
  - For each item:
    1. Calculate item's share of tax (if taxable): `(item price / sum of taxable items) × total tax`
    2. Calculate item's share of tip (if tippable): `(item price / sum of tippable items) × total tip`
    3. Item total = `item price + item tax share + item tip share`
    4. Split item total evenly among assigned persons (or all persons if none assigned)
  
- **Results Display:**
  - List of all persons
  - For each person:
    - Items assigned (with breakdown showing item price, tax portion, tip portion)
    - Subtotal of their item prices
    - Their share of tax
    - Their share of tip
    - **Total amount owed** (sum of all their item totals)

---

## Data Structure

### Item Object
```javascript
{
  id: uniqueId,
  name: string,
  price: number,
  taxable: boolean,      // default: true
  tippable: boolean,      // default: true
  memo: string,
  assignedPersons: [personId1, personId2, ...],  // empty array = all persons
  isPlug: boolean        // true if this is an auto-created plug item
}
```

### Person Object
```javascript
{
  id: uniqueId,
  name: string
}
```

### Bill Object
```javascript
{
  items: [Item],
  persons: [Person],
  subtotal: number,      // user-entered bill subtotal
  tax: number,           // user-entered tax amount
  tip: number            // user-entered tip amount
}
```

---

## Calculation Logic

### Tax Distribution
- Tax is user-entered as a dollar amount
- Tax is distributed **proportionally** among **taxable items only**
- Formula for each taxable item's tax share:
  ```
  itemTaxShare = (itemPrice / sumOfAllTaxableItems) × totalTax
  ```
- If no items are taxable, tax is not distributed (edge case to handle)

### Tip Distribution
- Tip is user-entered as a dollar amount
- Tip is distributed **proportionally** among **tippable items only**
- Formula for each tippable item's tip share:
  ```
  itemTipShare = (itemPrice / sumOfAllTippableItems) × totalTip
  ```
- If no items are tippable, tip is not distributed (edge case to handle)

### Item Assignment & Splitting
- Each item maintains a list of assigned persons (`assignedPersons` array)
- If `assignedPersons` is empty: item splits evenly among **all persons** on the check
- If `assignedPersons` has persons: item splits evenly among **only those assigned persons**
- Formula for each person's share of an item:
  ```
  personItemShare = (itemPrice + itemTaxShare + itemTipShare) / numberOfAssignedPersons
  ```
- If item has no assigned persons, `numberOfAssignedPersons` = total number of persons

### Plug Item
- Created automatically when `sum of item prices ≠ entered subtotal`
- Plug item price = `enteredSubtotal - sumOfItemPrices`
- Plug item properties:
  - Name: "plug" (or similar)
  - Memo: "plug" (or explanatory text)
  - Taxable: true (default)
  - Tippable: true (default)
  - Assigned persons: empty array (splits among all persons)
  - `isPlug: true`
- **Visual Treatment:**
  - Always highlighted/obvious styling (border, background color, icon)
  - If negative amount: Red background/text with warning message
  - Warning text: "This is a plug item to balance the bill. Amount: $X.XX"

---

## UI/UX Flow

### Single Page Application Layout
All features on one page with sections:
1. **Person Management Section** (top)
2. **Item Entry Section** (middle)
3. **Bill Totals Section** (below items)
4. **Results Section** (bottom, updates automatically or on calculate button)

### Step 1: Manage Persons
1. Default person created automatically ("Person 1" or similar)
2. User can add more persons at any time
3. User can remove persons (except if it's the last one)
4. Persons list visible and editable throughout

### Step 2: Enter Items
1. User adds items one by one
2. For each item: set price, taxable, tippable, memo, assign persons
3. Items are editable (can modify any field after creation)
4. Running subtotal updates in real-time
5. Plug item created automatically if items don't match subtotal

### Step 3: Enter Bill Totals
1. User enters actual subtotal from bill
2. System validates/creates plug if needed (with visual indication)
3. User enters tax amount (derived tax rate shown)
4. User enters tip amount

### Step 4: View Results
1. Results update automatically or on "Calculate" button
2. Results section displays:
   - Per-person breakdown
   - Itemized list per person (showing item price, tax portion, tip portion)
   - Final totals per person

---

## Resolved Decisions

### ✅ Tax Calculation
- Tax is user-entered as dollar amount
- Tax distributed proportionally among taxable items only
- Derived tax rate displayed: `(Tax / Subtotal) × 100%`

### ✅ Tip Calculation
- Tip is user-entered as dollar amount
- Tip distributed proportionally among tippable items only
- Each item has `tippable` attribute (default: true)

### ✅ Item Assignment
- Items maintain list of assigned persons
- If no persons assigned: splits among all persons
- If persons assigned: splits evenly among assigned persons only
- No group/subgroup concepts

### ✅ Plug Item
- Auto-created when items don't sum to subtotal
- Assigned to all persons (empty assignedPersons array)
- Visual treatment: always obvious, red if negative

### ✅ UI Preferences
- Single-page application
- Items are editable throughout
- Persons can be added/removed throughout
- Minimal styling until core features complete

### ✅ Edge Cases Handled
- No persons created: default to single person
- Negative plug item: red styling with warning
- Plug item always visually obvious

### ✅ Technical Preferences
- Standalone JavaScript (does not need MoneyApp)
- Vanilla JavaScript (no framework required initially)
- Minimal styling (focus on functionality first)

---

## Potential Confusing Areas & Solutions

### 1. Item Assignment Logic
- **Potential Confusion:** Empty assigned persons list = all persons (implicit behavior)
- **Solution:** 
  - Show "All persons" or "Everyone" label when no persons selected
  - Tooltip/help text: "Leave unselected to split among all persons"

### 2. Tax/Tip Proportional Distribution
- **Potential Confusion:** Tax and tip are split proportionally among items, not people
- **Solution:** 
  - Show breakdown in results: "Item X: $10.00 + $0.50 tax + $1.00 tip = $11.50"
  - Make it clear that tax/tip portions are calculated per item first, then split to people

### 3. Plug Item Visibility
- **Potential Confusion:** User might not notice plug item or understand why it exists
- **Solution:**
  - Always highlight plug item (border, background, icon)
  - Show warning/notice text: "Plug item created to balance bill"
  - If negative: red styling with explicit warning
  - Make plug item editable (user can adjust if needed)

### 4. Running Totals vs. Bill Subtotal
- **Potential Confusion:** Items total might not match bill subtotal
- **Solution:**
  - Label clearly: "Items Total: $X.XX" vs "Bill Subtotal: $Y.YY"
  - Show difference: "Difference: $Z.ZZ (plug item will be created)"
  - Visual indicator when they don't match

### 5. Tax/Tip on Plug Items
- **Resolved:** Plug items are taxable and tippable by default
- Plug items participate in tax and tip distribution like regular items
- User can edit plug item properties if needed

### 6. No Taxable/Tippable Items
- **Potential Confusion:** What if all items are non-taxable or non-tippable?
- **Solution:**
  - Show warning: "No taxable items. Tax will not be distributed."
  - Show warning: "No tippable items. Tip will not be distributed."
  - Allow user to proceed (tax/tip just won't be split)

---

## Next Steps

1. ✅ **Requirements clarified** - All questions answered
2. ✅ **Calculation logic finalized** - See Calculation Logic section
3. **Create file structure** - Standalone HTML/JS/CSS files
4. **Implement core data structures** - Item, Person, Bill objects
5. **Build UI components** - Person management, item form, totals, results
6. **Implement calculation engine** - Tax/tip distribution, person totals
7. **Add validation and error handling** - Input validation, edge cases
8. **Test edge cases** - No persons, no taxable items, negative plug, etc.

## File Structure

```
bill-splitter/
├── index.html          # Main HTML file
├── styles.css          # Minimal styling (basic layout only)
└── app.js              # Main JavaScript application
```

## Key Implementation Details

### Calculation Algorithm
```javascript
// 1. Calculate tax per taxable item
const taxableTotal = items.filter(i => i.taxable).reduce((sum, i) => sum + i.price, 0);
items.forEach(item => {
  if (item.taxable) {
    item.taxShare = (item.price / taxableTotal) * bill.tax;
  } else {
    item.taxShare = 0;
  }
});

// 2. Calculate tip per tippable item
const tippableTotal = items.filter(i => i.tippable).reduce((sum, i) => sum + i.price, 0);
items.forEach(item => {
  if (item.tippable) {
    item.tipShare = (item.price / tippableTotal) * bill.tip;
  } else {
    item.tipShare = 0;
  }
});

// 3. Calculate item total
items.forEach(item => {
  item.total = item.price + item.taxShare + item.tipShare;
});

// 4. Distribute items to persons
persons.forEach(person => {
  person.total = 0;
  person.items = [];
  
  items.forEach(item => {
    const assignedPersons = item.assignedPersons.length > 0 
      ? item.assignedPersons 
      : persons.map(p => p.id);
    
    if (assignedPersons.includes(person.id)) {
      const share = item.total / assignedPersons.length;
      person.total += share;
      person.items.push({
        item: item,
        share: share,
        taxPortion: item.taxShare / assignedPersons.length,
        tipPortion: item.tipShare / assignedPersons.length
      });
    }
  });
});
```

---

## Implementation Priority

### Phase 1: Core Functionality (MVP)
- ✅ Person management (add/remove, default person)
- ✅ Item entry form (price, name, memo)
- ✅ Item assignment (multi-select persons, empty = all persons)
- ✅ Subtotal entry
- ✅ Plug item auto-creation (with basic styling)
- ✅ Tax entry (with derived rate display)
- ✅ Tip entry
- ✅ Basic calculation (item totals split to persons)
- ✅ Results display (per-person breakdown)

### Phase 2: Tax & Tip Distribution
- ✅ Taxable attribute per item
- ✅ Tippable attribute per item
- ✅ Proportional tax distribution (among taxable items)
- ✅ Proportional tip distribution (among tippable items)
- ✅ Item-level tax/tip breakdown in results

### Phase 3: Polish & Edge Cases
- ✅ Plug item visual treatment (obvious styling, red if negative)
- ✅ Item editing functionality
- ✅ Validation and error messages
- ✅ Edge case handling (no taxable/tippable items, etc.)
- ✅ Better labels and help text

### Phase 4: Enhanced Features (Future)
- Export/save functionality
- Mobile responsiveness
- Better styling/UI polish
- Undo/redo functionality
- Item reordering

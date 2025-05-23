let currentCategory = 'vehicules';
let categories = [];
let items = {};
let currentCredits = 0;
let isInitialized = false;
let purchaseHistory = [];
let isAdmin = false;

function createItemCard(item, category) {
    const card = document.createElement('div');
    card.className = 'item-card';
    
    const tagsHtml = item.tags.map(tag => {
        const className = tag.toLowerCase().replace(' ', '-');
        return `<span class="tag tag-${className}">${tag}</span>`;
    }).join('');
    

    let actionButton = '';
    if (category === 'vehicules') {
        actionButton = `<button class="preview-btn" data-vehicle="${item.spawnName}">Prévisualiser</button>`;
    } else if (category === 'packs') {
        actionButton = `<button class="preview-btn">Prévisualiser</button>`;
    } else if (category === 'admin') {
        if (item.adminAction === 'add') {
            actionButton = `<button class="buy-btn admin-action" data-action="${item.adminAction}">Ajouter</button>`;
        } else if (item.adminAction === 'remove') {
            actionButton = `<button class="buy-btn admin-action" data-action="${item.adminAction}">Retirer</button>`;
        }
    } else {
        actionButton = `<button class="buy-btn" data-item="${item.spawnName}">ACHETER</button>`;
    }
    
    card.innerHTML = `
        <div class="vehicle-image">
            <img src="${item.image}" alt="${item.name}">
            <div class="vehicle-tags">
                ${tagsHtml}
            </div>
        </div>
        <div class="vehicle-info">
            <div class="vehicle-name">${item.name}</div>
            <div class="vehicle-description">${item.description || ''}</div>
            <div class="vehicle-controls">
                ${category !== 'admin' ? `
                <div class="quantity-control">
                    <button class="quantity-btn decrease">◀</button>
                    <input type="text" class="quantity" value="1" readonly>
                    <button class="quantity-btn increase">▶</button>
                </div>
                <div class="price">
                    <i class="fas fa-gem"></i>
                    <span>${item.price || 0}</span>
                </div>` : ''}
                ${actionButton}
            </div>
        </div>
    `;
    

    if (category === 'packs') {
        const previewBtn = card.querySelector('.preview-btn');
        previewBtn.onclick = () => showPackPreview(item);
    }


    if (category === 'caisses') {
        const buyBtn = card.querySelector('.buy-btn');
        if (buyBtn) {
            buyBtn.textContent = 'Prévisualiser';
            buyBtn.onclick = () => showCasePreview(item);
        }
    }
    

    if (category === 'admin') {
        const adminBtn = card.querySelector('.admin-action');
        if (adminBtn) {
            adminBtn.onclick = () => {
                if (item.adminAction === 'add') {
                    showAdminModal('add');
                } else if (item.adminAction === 'remove') {
                    showAdminModal('remove');
                }
            };
        }
    }

    return card;
}


function createHistoryCard(item) {
    const card = document.createElement('div');
    card.className = 'vehicle-card';
    
    const purchaseDate = new Date(item.purchase_date);
    const formattedDate = purchaseDate.toLocaleDateString('fr-FR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
    
    card.innerHTML = `
        <div class="vehicle-image">
            <img src="${findItemImage(item.item_name)}" alt="${item.item_label}">
        </div>
        <div class="vehicle-info">
            <div class="vehicle-name">${item.item_label}</div>
            <div class="vehicle-controls">
                <div class="price">
                    <i class="fas fa-gem"></i>
                    <span>${item.price}</span>
                </div>
                <div class="purchase-date">
                    Acheté le ${formattedDate}
                </div>
            </div>
        </div>
    `;
    
    return card;
}


function findItemImage(itemName) {
    for (const category in items) {
        const item = items[category].find(i => i.spawnName === itemName);
        if (item) {
            return item.image;
        }
    }
    return 'default-image.jpg';
}

function cleanupUI() {
    const sidebar = document.querySelector('.sidebar');
    const logo = sidebar.querySelector('.logo');
    const footer = sidebar.querySelector('.footer');
    while (logo.nextElementSibling && logo.nextElementSibling !== footer) {
        sidebar.removeChild(logo.nextElementSibling);
    }
    const container = document.querySelector('.vehicles-grid');
    container.innerHTML = '';
    currentCategory = 'vehicules';
}

function updateDisplay() {
    const grid = document.querySelector('.vehicles-grid');
    grid.innerHTML = '';
    
    const activeTab = document.querySelector('.tab.active').dataset.tab;
    
    if (activeTab === 'history') {
        if (purchaseHistory.length === 0) {
            const emptyMessage = document.createElement('div');
            emptyMessage.className = 'empty-history';
            emptyMessage.innerHTML = `
                <i class="fas fa-history"></i>
                <span>Historique d'achat vide</span>
            `;
            grid.appendChild(emptyMessage);
        } else {
            purchaseHistory.forEach(item => {
                grid.appendChild(createHistoryCard(item));
            });
        }
    } else if (activeTab === 'shop') {
        if (items[currentCategory]) {
            items[currentCategory].forEach(item => {
                grid.appendChild(createItemCard(item, currentCategory));
            });
        }
    } else if (activeTab === 'inventory') {
        loadPendingItems();
    }
    
    initializeEventListeners();
}

function initializeEventListeners() {
    document.querySelectorAll('.quantity-btn').forEach(button => {
        button.addEventListener('click', function() {
            const input = this.parentNode.querySelector('.quantity');
            let value = parseInt(input.value);
            
            if (this.classList.contains('increase') && value < 99) {
                input.value = value + 1;
            } else if (this.classList.contains('decrease') && value > 1) {
                input.value = value - 1;
            }
        });
    });
    document.querySelectorAll('.preview-btn').forEach(button => {
        button.addEventListener('click', function() {
            const vehicleName = this.dataset.vehicle;
            if (vehicleName) {
                fetch(`https://${GetParentResourceName()}/previewVehicle`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        vehicle: vehicleName
                    })
                });
            }
        });
    });
    document.querySelectorAll('.buy-btn').forEach(button => {
        button.addEventListener('click', function() {
            if (this.classList.contains('admin-action')) {
                const action = this.dataset.action;
                if (action === 'add') {
                    showAdminModal('add');
                } else if (action === 'remove') {
                    showAdminModal('remove');
                }
                return;
            }
            const itemName = this.dataset.item;
            const quantity = parseInt(this.closest('.vehicle-controls').querySelector('.quantity').value);
            
            if (!itemName) {
                console.error('Item name is missing');
                return;
            }

            if (!currentCategory) {
                console.error('Category is missing');
                return;
            }

            fetch(`https://${GetParentResourceName()}/buyItem`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    itemName: itemName,
                    quantity: quantity,
                    category: currentCategory
                })
            }).then(response => {
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                return response.json();
            }).then(data => {
                if (data.success) {
                    if (data.credits !== undefined) {
                        updateCredits(data.credits);
                    }
                } else {
                    console.error('Purchase failed:', data.message);
                }
            }).catch(error => {
                console.error('Error during purchase:', error);
            });
        });
    });
}

function initializeNavigation() {
    if (isInitialized) return;
    
    const sidebar = document.querySelector('.sidebar');
    const navContent = categories.map(category => {
        if (category.adminOnly && !isAdmin) {
            return '';
        }
        
        return `
            <a href="#" class="nav-item" data-category="${category.id}">
                <i class="fas ${category.icon}"></i>
                ${category.label}
            </a>
        `;
    }).join('');
    const logo = sidebar.querySelector('.logo');
    logo.insertAdjacentHTML('afterend', navContent);
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', function(e) {
            e.preventDefault();
            const categoryId = this.dataset.category;
            document.querySelectorAll('.nav-item').forEach(navItem => {
                navItem.classList.remove('active');
            });
            this.classList.add('active');
            
            currentCategory = categoryId;
            updateDisplay();
        });
    });
    isInitialized = true;
    const firstCategory = document.querySelector('.nav-item');
    if (firstCategory) {
        firstCategory.classList.add('active');
    }
}

function initializeUI() {
    document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', function() {
            document.querySelector('.tab.active').classList.remove('active');
            this.classList.add('active');
            updateDisplay();
        });
    });
    document.querySelector('.close-btn').addEventListener('click', function() {
        cleanupUI();
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST'
        });
    });
}

window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch (data.type) {
        case 'show':
            document.body.style.display = 'block';
            break;
            
        case 'hide':
            document.body.style.display = 'none';
            cleanupUI();
            isInitialized = false; 
            break;
            
        case 'updateCredits':
            currentCredits = data.credits;
            document.querySelector('.footer span').textContent = data.credits;
            break;
            
        case 'updateUserInfo':
            document.querySelector('.user-id').textContent = `ID - ${data.identifier}`;
            document.querySelector('.user-name').textContent = data.name;
            break;
            
        case 'initializeData':
            categories = data.categories;
            items = data.items;
            isAdmin = data.isAdmin;
            cleanupUI();
            initializeNavigation();
            updateDisplay();
            break;
            
        case 'updatePurchaseHistory':
            purchaseHistory = data.history;
            if (document.querySelector('.tab.active').dataset.tab === 'history') {
                updateDisplay();
            }
            break;
            
        case 'updatePendingItemCount':
            const inventoryTab = document.querySelector('.tab[data-tab="inventory"]');
            if (inventoryTab) {
                inventoryTab.textContent = `Inventaire (${data.count})`;
            }
            break;
            
        case 'updateAdminStatus':
            isAdmin = data.isAdmin;
            cleanupUI();
            initializeNavigation();
            updateDisplay();
            break;
    }
});

document.addEventListener('DOMContentLoaded', initializeUI);
document.addEventListener('contextmenu', function(e) {
    e.preventDefault();
});

function showPackPreview(pack) {
    const modal = document.querySelector('.pack-preview-modal');
    const title = modal.querySelector('.pack-title');
    const itemsContainer = modal.querySelector('.pack-items-scroll');
    const priceSpan = modal.querySelector('.pack-price span');
    const buyButton = modal.querySelector('.buy-pack-btn');
    title.textContent = pack.name;
    priceSpan.textContent = pack.price;
    itemsContainer.innerHTML = '';
    function createPackItem(item, type, quantity = null) {
        const div = document.createElement('div');
        div.className = 'pack-item';
        div.innerHTML = `
            <img src="${item.image}" alt="${item.name}">
            <div class="pack-item-type">${type}</div>
            <div class="pack-item-name">${item.name}</div>
            <div class="pack-item-quantity">Quantité : ${quantity || 1}</div>
        `;
        return div;
    }
    if (pack.content.vehicles) {
        pack.content.vehicles.forEach(vehicle => {
            itemsContainer.appendChild(createPackItem(vehicle, 'Véhicule', 1));
        });
    }

    if (pack.content.weapons) {
        pack.content.weapons.forEach(weapon => {
            itemsContainer.appendChild(createPackItem(weapon, 'Arme', 1));
        });
    }

    if (pack.content.items) {
        pack.content.items.forEach(item => {
            itemsContainer.appendChild(createPackItem(item, 'Item', item.count));
        });
    }
    buyButton.onclick = () => {
        fetch(`https://${GetParentResourceName()}/buyItem`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                itemName: pack.spawnName,
                category: 'packs',
                quantity: 1
            })
        });
        closePackPreview();
    };

    modal.style.display = 'flex';
}
function closePackPreview() {
    const modal = document.querySelector('.pack-preview-modal');
    modal.style.display = 'none';
}
document.querySelector('.close-preview-btn').addEventListener('click', closePackPreview);
function showCaseOpening(caseItem) {
    const modal = document.querySelector('.case-opening-modal');
    const title = modal.querySelector('.case-title');
    const itemsScroll = modal.querySelector('.case-items-scroll');
    const priceSpan = modal.querySelector('.case-price span');
    const openButton = modal.querySelector('.open-case-btn');
    
    title.textContent = caseItem.name;
    priceSpan.textContent = caseItem.price;
    
    function createCaseItem(item, isWinner = false) {
        const div = document.createElement('div');
        div.className = 'case-item';
        if (isWinner) {
            div.classList.add('winning-item');
        }
        div.innerHTML = `
            <img src="${item.image}" alt="${item.name}">
            <div class="case-item-name">${item.name}</div>
            <div class="case-item-rarity ${item.rarity}">${item.rarity}</div>
        `;
        return div;
    }
    
    itemsScroll.innerHTML = '';
    const previewItems = [];
    for (let i = 0; i < 50; i++) {
        previewItems.push(caseItem.possible_items[Math.floor(Math.random() * caseItem.possible_items.length)]);
    }
    previewItems.forEach(item => {
        itemsScroll.appendChild(createCaseItem(item));
    });
    
    const itemWidth = 160;
    const selectorCenterX = modal.querySelector('.case-selector').offsetLeft + 
                           (modal.querySelector('.case-selector').offsetWidth / 2);
    const initialPosition = -((previewItems.length / 2) * itemWidth) + (selectorCenterX - (itemWidth / 2));
    itemsScroll.style.transform = `translateX(${initialPosition}px)`;
    

    openButton.disabled = false;
    
    openButton.addEventListener('click', function openCaseHandler() {
        fetch(`https://${GetParentResourceName()}/showNotification`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                type: 'info',
                message: 'Clic sur Ouvrir détecté'
            })
        });
        
        if (currentCredits < caseItem.price) {
            fetch(`https://${GetParentResourceName()}/showNotification`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    type: 'error',
                    message: 'Vous n\'avez pas assez de crédits'
                })
            });
            return;
        }
        

        openButton.disabled = true;
        

        openButton.removeEventListener('click', openCaseHandler);
        
        fetch(`https://${GetParentResourceName()}/getBoxWinningItem`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                caseId: caseItem.spawnName
            })
        }).then(response => response.json())
        .then(data => {
            if (!data.success) {
                openButton.disabled = false;
                fetch(`https://${GetParentResourceName()}/showNotification`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        type: 'error',
                        message: 'Erreur lors de la détermination du prix'
                    })
                });
                return;
            }
            
            const winningIndex = data.winningIndex;
            const winningItem = data.winningItem;
            
            fetch(`https://${GetParentResourceName()}/buyItem`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    itemName: caseItem.spawnName,
                    category: 'caisses',
                    quantity: 1,
                    isOpeningCase: true
                })
            })
            .then(response => {
                return response.json();
            })
            .then(buyData => {
                if (!buyData.success) {
                    openButton.disabled = false;
                    fetch(`https://${GetParentResourceName()}/showNotification`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({
                            type: 'error',
                            message: buyData.message || 'Échec de l\'achat'
                        })
                    });
                    return;
                }
                
                const sequence = [];
                const totalItems = 50;
                const selectorPosition = 25;
                
                for (let i = 0; i < totalItems; i++) {
                    if (i === selectorPosition) {
                        sequence.push(winningItem);
                    } else {
                        let randomItem;
                        do {
                            randomItem = caseItem.possible_items[Math.floor(Math.random() * caseItem.possible_items.length)];
                        } while (i > selectorPosition - 3 && i < selectorPosition + 3 && randomItem.name === winningItem.name);
                        
                        sequence.push(randomItem);
                    }
                }
                
                itemsScroll.innerHTML = '';
                sequence.forEach((item, index) => {
                    const isWinner = index === selectorPosition;
                    itemsScroll.appendChild(createCaseItem(item, isWinner));
                });
                
                itemsScroll.style.transform = 'translateX(0)';
                
                const caseSelector = modal.querySelector('.case-selector');
                const selectorCenterX = caseSelector.offsetLeft + (caseSelector.offsetWidth / 2);
                const finalPosition = -(selectorPosition * itemWidth) + (selectorCenterX - (itemWidth / 2));
                
                let duration = 8000;
                let startTime = null;
                let startPosition = 0;
                
                function animate(currentTime) {
                    if (!startTime) startTime = currentTime;
                    const elapsed = currentTime - startTime;
                    
                    if (elapsed < duration) {
                        const progress = elapsed / duration;
                        const easeOut = 1 - Math.pow(1 - progress, 4);
                        const currentPosition = startPosition + (finalPosition - startPosition) * easeOut;
                        
                        itemsScroll.style.transform = `translateX(${currentPosition}px)`;
                        requestAnimationFrame(animate);
                    } else {
                        itemsScroll.style.transform = `translateX(${finalPosition}px)`;
                        
                        const winningElement = itemsScroll.children[selectorPosition];
                        if (winningElement) {
                            winningElement.classList.add('highlighted');
                        }
                        
                        fetch(`https://${GetParentResourceName()}/showNotification`, {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json'
                            },
                            body: JSON.stringify({
                                type: 'success',
                                message: `Vous avez gagné : ${winningItem.name}`
                            })
                        });
                        
                        fetch(`https://${GetParentResourceName()}/casePrizeWon`, {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json'
                            },
                            body: JSON.stringify({
                                caseId: caseItem.spawnName,
                                prizeItem: winningItem
                            })
                        });
                        
                        setTimeout(() => {
                            openButton.disabled = false;
                        }, 2000);
                    }
                }
                
                requestAnimationFrame(animate);
            });
        })
        .catch(error => {
            console.error('Erreur:', error);
            openButton.disabled = false;
        });
    }, { once: true });
    
    modal.style.display = 'flex';
}

function closeCaseOpening() {
    const modal = document.querySelector('.case-opening-modal');
    modal.style.display = 'none';
}

document.querySelector('.close-case-btn').addEventListener('click', closeCaseOpening);

function showCasePreview(caseItem) {
    const modal = document.querySelector('.case-preview-modal');
    const title = modal.querySelector('.case-preview-title');
    const itemsContainer = modal.querySelector('.case-preview-items');
    const priceSpan = modal.querySelector('.case-price span');
    const openButton = modal.querySelector('.start-case-opening-btn');
    title.textContent = `${caseItem.name} - Contenu possible`;
    priceSpan.textContent = caseItem.price;
    itemsContainer.innerHTML = '';
    function createPreviewItem(item) {
        const div = document.createElement('div');
        div.className = 'case-preview-item';
        
        let typeLabel = '';
        let extraInfo = '';
        
        switch(item.type) {
            case 'vehicle':
                typeLabel = 'Véhicule';
                break;
            case 'weapon':
                typeLabel = 'Arme';
                break;
            case 'money':
                typeLabel = 'Argent';
                extraInfo = `${item.amount.toLocaleString()} $`;
                break;
            case 'item':
                typeLabel = 'Item';
                if (item.count > 1) {
                    extraInfo = `Quantité : ${item.count}`;
                }
                break;
        }
        
        div.innerHTML = `
            <img src="${item.image}" alt="${item.name}">
            <div class="case-preview-item-name">${item.name}</div>
            <div class="case-preview-item-type">${typeLabel}${extraInfo ? ` - ${extraInfo}` : ''}</div>
            <div class="case-preview-item-rarity ${item.rarity}">${item.rarity}</div>
        `;
        return div;
    }
    const rarityOrder = {
        'legendary': 0,
        'epic': 1,
        'rare': 2,
        'uncommon': 3,
        'common': 4
    };
    
    const sortedItems = [...caseItem.possible_items].sort((a, b) => 
        rarityOrder[a.rarity] - rarityOrder[b.rarity]
    );
    sortedItems.forEach(item => {
        itemsContainer.appendChild(createPreviewItem(item));
    });
    openButton.onclick = () => {
        closeCasePreview();
        showCaseOpening(caseItem);
    };
    modal.style.display = 'flex';
}

function closeCasePreview() {
    const modal = document.querySelector('.case-preview-modal');
    modal.style.display = 'none';
}
document.querySelector('.close-case-preview-btn').addEventListener('click', closeCasePreview);
function createInventoryCard(item) {
    const card = document.createElement('div');
    card.className = 'item-card inventory-card';
    const purchaseDate = new Date(item.purchase_date);
    const formattedDate = purchaseDate.toLocaleDateString('fr-FR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
    let categoryIcon = 'fa-box';
    if (item.category === 'vehicules') categoryIcon = 'fa-car';
    else if (item.category === 'armes') categoryIcon = 'fa-gun';
    else if (item.category === 'consommables') categoryIcon = 'fa-shopping-cart';
    
    card.innerHTML = `
        <div class="vehicle-image">
            <img src="${findItemImage(item.item_name)}" alt="${item.item_label}">
            <div class="vehicle-tags">
                <span class="tag tag-${item.category}">${item.category}</span>
            </div>
        </div>
        <div class="vehicle-info">
            <div class="vehicle-name">${item.item_label}</div>
            <div class="vehicle-quantity">Quantité: ${item.quantity}</div>
            <div class="vehicle-date">Acheté le: ${formattedDate}</div>
            <div class="vehicle-controls inventory-controls">
                <div class="price">
                    <i class="fas fa-gem"></i>
                    <span>${item.price}</span>
                </div>
                <div class="inventory-buttons">
                    <button class="claim-btn" data-id="${item.id}">Réclamer</button>
                    <button class="refund-btn" data-id="${item.id}">Rembourser</button>
                </div>
            </div>
        </div>
    `;
    card.querySelector('.claim-btn').addEventListener('click', function() {
        const itemId = parseInt(this.dataset.id);
        
        fetch(`https://${GetParentResourceName()}/claimItem`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                itemId: itemId
            })
        }).then(response => response.json())
        .then(data => {
            if (data.success) {
                loadPendingItems();
            }
        });
    });
    card.querySelector('.refund-btn').addEventListener('click', function() {
        const itemId = parseInt(this.dataset.id);
        
        fetch(`https://${GetParentResourceName()}/refundItem`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                itemId: itemId
            })
        }).then(response => response.json())
        .then(data => {
            if (data.success) {
                loadPendingItems();
            }
        });
    });
    
    return card;
}
function loadPendingItems() {
    fetch(`https://${GetParentResourceName()}/getPendingItems`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    }).then(response => response.json())
    .then(items => {
        const grid = document.querySelector('.vehicles-grid');
        grid.innerHTML = '';
        
        if (items.length === 0) {
            const emptyMessage = document.createElement('div');
            emptyMessage.className = 'empty-inventory';
            emptyMessage.innerHTML = `
                <i class="fas fa-inbox"></i>
                <span>Inventaire vide</span>
            `;
            grid.appendChild(emptyMessage);
        } else {
            items.forEach(item => {
                grid.appendChild(createInventoryCard(item));
            });
        }
        const inventoryTab = document.querySelector('.tab[data-tab="inventory"]');
        if (inventoryTab) {
            inventoryTab.textContent = `Inventaire (${items.length})`;
        }
    });
}
function showAdminModal(action) {
    if (!document.querySelector('.admin-modal')) {
        const modal = document.createElement('div');
        modal.className = 'admin-modal';
        modal.innerHTML = `
            <div class="admin-modal-content">
                <div class="admin-modal-header">
                    <h2 class="admin-modal-title"></h2>
                    <button class="close-admin-modal">×</button>
                </div>
                <div class="admin-modal-body">
                    <div class="admin-input-group">
                        <label>ID du joueur</label>
                        <input type="number" id="admin-player-id" placeholder="Entrez l'ID du joueur" min="1">
                    </div>
                    <div class="admin-input-group">
                        <label>Montant</label>
                        <input type="number" id="admin-amount" placeholder="Entrez le montant" min="1">
                    </div>
                </div>
                <div class="admin-modal-footer">
                    <button class="admin-cancel-btn">Annuler</button>
                    <button class="admin-confirm-btn"></button>
                </div>
            </div>
        `;
        document.body.appendChild(modal);
        modal.querySelector('.close-admin-modal').addEventListener('click', closeAdminModal);
        modal.querySelector('.admin-cancel-btn').addEventListener('click', closeAdminModal);
    }
    const modal = document.querySelector('.admin-modal');
    const title = modal.querySelector('.admin-modal-title');
    const confirmBtn = modal.querySelector('.admin-confirm-btn');
    
    if (action === 'add') {
        title.textContent = 'Ajouter des coins';
        confirmBtn.textContent = 'Ajouter';
        confirmBtn.dataset.action = 'add';
    } else if (action === 'remove') {
        title.textContent = 'Retirer des coins';
        confirmBtn.textContent = 'Retirer';
        confirmBtn.dataset.action = 'remove';
    }
    confirmBtn.onclick = function() {
        const playerId = document.getElementById('admin-player-id').value;
        const amount = document.getElementById('admin-amount').value;
        
        if (!playerId || !amount) {
            fetch(`https://${GetParentResourceName()}/showNotification`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    message: '~r~Veuillez remplir tous les champs'
                })
            });
            return;
        }
        const endpoint = action === 'add' ? 'adminAddCredits' : 'adminRemoveCredits';
        fetch(`https://${GetParentResourceName()}/${endpoint}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                targetId: parseInt(playerId),
                amount: parseInt(amount)
            })
        }).then(response => response.json())
        .then(data => {
            if (data.success) {
                fetch(`https://${GetParentResourceName()}/showNotification`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        message: `~g~${data.message}`
                    })
                });
                closeAdminModal();
            } else {
                fetch(`https://${GetParentResourceName()}/showNotification`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        message: `~r~${data.message}`
                    })
                });
            }
        })
        .catch(error => {
            console.error('Error:', error);
            fetch(`https://${GetParentResourceName()}/showNotification`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    message: '~r~Erreur lors de la communication avec le serveur'
                })
            });
        });
    };

    modal.style.display = 'flex';
}

function closeAdminModal() {
    const modal = document.querySelector('.admin-modal');
    if (modal) {
        document.getElementById('admin-player-id').value = '';
        document.getElementById('admin-amount').value = '';
        modal.style.display = 'none';
    }
} 
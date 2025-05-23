Config = {}

Config.Categories = {
    {
        id = "vehicules",
        label = "Véhicules",
        icon = "fa-car"
    },
    {
        id = "armes",
        label = "Armes",
        icon = "fa-gun"
    },
    {
        id = "caisses",
        label = "Caisses",
        icon = "fa-box"
    },
    {
        id = "packs",
        label = "Packs",
        icon = "fa-cubes"
    },
    {
        id = "consommables",
        label = "Consommables",
        icon = "fa-shopping-cart"
    },
    {
        id = "admin",
        label = "Gestion ADMIN",
        icon = "fa-shield-alt",
        adminOnly = true
    }
}

Config.Items = {
    vehicules = {
        {
            name = "Sultan",
            price = 2500,
            spawnName = "sultan",
            image = "https://i.postimg.cc/sgJsZsbq/764c6d-2-1.webp",
            tags = {"NOUVEAU", "BEST SELLER"},
            description = "Une voiture de sport exclusive"
        },
        {
            name = "Bmw M4",
            price = 2500,
            spawnName = "sultan",
            image = "https://i.postimg.cc/sgJsZsbq/764c6d-2-1.webp",
            tags = {"NOUVEAU", "PROMO"},
            description = "Une voiture de sport exclusive"
        },
        {
            name = "Lamborghini Aventador",
            price = 2500,
            spawnName = "sultan",
            image = "https://i.postimg.cc/sgJsZsbq/764c6d-2-1.webp",
            tags = {"ALEZONTOP"},
            description = "Une voiture de sport exclusive"
        },
        {
            name = "Mercedes G63",
            price = 2500,
            spawnName = "sultan",
            image = "https://i.postimg.cc/sgJsZsbq/764c6d-2-1.webp",
            tags = {"SALUT", "BEST SELLER"},
            description = "Une voiture de sport exclusive"
        },
        {
            name = "Bugatti Chiron",
            price = 2500,
            spawnName = "sultan",
            image = "https://i.postimg.cc/sgJsZsbq/764c6d-2-1.webp",
            tags = {"NOUVEAU", "BEST SELLER"},
            description = "Une voiture de sport exclusive"
        }
    },
    armes = {
        {
            name = "Pistolet",
            price = 1000,
            spawnName = "weapon_pistol",
            image = "https://i.postimg.cc/gJWbN01G/Pistol-GTAV-1.webp",
            tags = {"PROMO"},
            description = "Pistolet précision accrue"
        }
    },
    caisses = {
        {
            name = "Caisse Mystère",
            price = 500,
            spawnName = "mystery_box",
            image = "https://i.postimg.cc/tgGcHMk5/loot-box-in-front-of-a-overwatch.png",
            tags = {"PROMOTION"},
            description = "Contient des objets aléatoires rares",
            possible_items = {
                {
                    name = "Sultan RS",
                    type = "vehicle",
                    spawnName = "sultanrs",
                    image = "https://i.postimg.cc/sgJsZsbq/764c6d-2-1.webp",
                    rarity = "legendary"
                },
                {
                    name = "Pistolet MK2",
                    type = "weapon",
                    spawnName = "weapon_pistol_mk2",
                    image = "https://i.postimg.cc/sgJsZsbq/764c6d-2-1.webp",
                    rarity = "epic"
                },
                {
                    name = "Eau",
                    type = "item",
                    spawnName = "water",
                    count = 5,
                    image = "https://i.postimg.cc/7hCvLT2M/drink-water.png",
                    rarity = "rare"
                },
                {
                    name = "Argent",
                    type = "money",
                    amount = 50000,
                    image = "https://i.postimg.cc/sgJsZsbq/764c6d-2-1.webp",
                    rarity = "uncommon"
                },
                {
                    name = "Pain",
                    type = "item",
                    spawnName = "bread",
                    count = 3,
                    image = "https://i.postimg.cc/sgJsZsbq/764c6d-2-1.webp",
                    rarity = "common"
                }
            }
        }
    },
    packs = {
        {
            name = "Pack Débutant",
            price = 2000,
            spawnName = "starter_pack",
            image = "https://i.postimg.cc/sgJsZsbq/764c6d-2-1.webp",
            tags = {"BEST SELLER"},
            description = "Pack idéal pour bien démarrer",
            content = {
                vehicles = {
                    {
                        name = "Sultan RS",
                        model = "sultanrs",
                        image = "https://i.postimg.cc/sgJsZsbq/764c6d-2-1.webp"
                    }
                },
                weapons = {
                    {
                        name = "Pistolet",
                        model = "weapon_pistol",
                        ammo = 100,
                        image = "https://i.postimg.cc/gJWbN01G/Pistol-GTAV-1.webp"
                    }
                },
                items = {
                    {
                        name = "Pain",
                        item = "bread",
                        count = 5,
                        image = "https://i.postimg.cc/QtYGsqHd/bread.png"
                    },
                    {
                        name = "Eau",
                        item = "water",
                        count = 3,
                        image = "https://i.postimg.cc/7hCvLT2M/drink-water.png"
                    }
                }
            }
        }
    },
    consommables = {
        {
            name = "Pain",
            price = 100,
            spawnName = "bread",
            image = "https://i.postimg.cc/QtYGsqHd/bread.png",
            tags = {"NOURRITURE"},
            description = "Du pain frais pour vous restaurer"
        },
        {
            name = "Eau",
            price = 50,
            spawnName = "water",
            image = "https://i.postimg.cc/7hCvLT2M/drink-water.png",
            tags = {"BOISSON"},
            description = "Une bouteille d'eau fraîche"
        }
    },
    admin = {
        {
            name = "Ajouter coins",
            spawnName = "add_coins",
            image = "https://i.postimg.cc/wTpXkYWg/5b701c596c0b06288e1f35f03b32f1a5.png",
            tags = {"ADMIN"},
            description = "Ajouter des coins à un joueur",
            adminAction = "add"
        },
        {
            name = "Retirer coins",
            spawnName = "remove_coins",
            image = "https://i.postimg.cc/wTpXkYWg/5b701c596c0b06288e1f35f03b32f1a5.png",
            tags = {"ADMIN"},
            description = "Retirer des coins à un joueur",
            adminAction = "remove"
        }
    }
}

Config.PreviewLocation = {
    coords = vector4(-1095.51, -3196.6, 13.94, 60.0),
    camera = {
        offset = vector3(3.0, 3.0, 2.0),
        fov = 50.0
    }
}

Config.Permissions = {
    addCredits = 'admin' -- PAS OBLIGATOIRE CEST SEULEMENT POUR LA CONSOLE /ADDCREDITS MAIS VOUS POUVEZ EN AJOUTER DEPUIS LINTERFACE
}

Config.Database = {
    tableName = 'user_credits', -- NE PAS TOUCHER
    vehicleTable = 'owned_vehicles' -- TABLE POUR LES VEHICULES
}


Config.WeaponItem = true -- TRUE = ARME EN ITEM, FALSE = ARME EN /GIVEWEAPON
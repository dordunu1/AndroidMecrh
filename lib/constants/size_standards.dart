// ISO Standard Size Definitions for Different Product Categories
const MENS_CLOTHING_SIZES = {
  'Shirts & T-Shirts': [
    'XS (34-36)',
    'S (36-38)',
    'M (38-40)',
    'L (40-42)',
    'XL (42-44)',
    '2XL (44-46)',
    '3XL (46-48)',
  ],
  'Pants & Trousers': [
    'W28 L30', 'W28 L32',
    'W30 L30', 'W30 L32', 'W30 L34',
    'W32 L30', 'W32 L32', 'W32 L34',
    'W34 L30', 'W34 L32', 'W34 L34',
    'W36 L30', 'W36 L32', 'W36 L34',
    'W38 L30', 'W38 L32', 'W38 L34',
  ],
  'Suits': [
    '36R', '38R', '40R', '42R', '44R', '46R',
    '38L', '40L', '42L', '44L', '46L',
    '38S', '40S', '42S', '44S',
  ],
};

const WOMENS_CLOTHING_SIZES = {
  'Dresses & Tops': [
    'XXS (0-2)',
    'XS (2-4)',
    'S (4-6)',
    'M (8-10)',
    'L (12-14)',
    'XL (16-18)',
    '2XL (20-22)',
  ],
  'Pants & Skirts': [
    '00 (23-24)',
    '0 (25-26)',
    '2 (26-27)',
    '4 (27-28)',
    '6 (28-29)',
    '8 (29-30)',
    '10 (30-31)',
    '12 (31-32)',
    '14 (33-34)',
    '16 (35-36)',
  ],
  'Blouses': [
    'XXS (30)',
    'XS (32)',
    'S (34)',
    'M (36)',
    'L (38)',
    'XL (40)',
    '2XL (42)',
  ],
};

const SHOE_SIZES = {
  'US-EU-UK Men': [
    'US 6 / EU 39 / UK 5.5',
    'US 7 / EU 40 / UK 6.5',
    'US 8 / EU 41 / UK 7.5',
    'US 9 / EU 42 / UK 8.5',
    'US 10 / EU 43 / UK 9.5',
    'US 11 / EU 44 / UK 10.5',
    'US 12 / EU 45 / UK 11.5',
    'US 13 / EU 46 / UK 12.5',
  ],
  'US-EU-UK Women': [
    'US 5 / EU 35-36 / UK 3',
    'US 6 / EU 36-37 / UK 4',
    'US 7 / EU 37-38 / UK 5',
    'US 8 / EU 38-39 / UK 6',
    'US 9 / EU 39-40 / UK 7',
    'US 10 / EU 40-41 / UK 8',
    'US 11 / EU 41-42 / UK 9',
  ],
  'Kids': [
    'US 10C / EU 27',
    'US 11C / EU 28',
    'US 12C / EU 30',
    'US 13C / EU 31',
    'US 1Y / EU 32',
    'US 2Y / EU 33',
    'US 3Y / EU 34',
  ],
};

const RING_SIZES = {
  'US-UK': [
    'US 3 / UK F',
    'US 4 / UK H',
    'US 5 / UK J',
    'US 6 / UK L',
    'US 7 / UK N',
    'US 8 / UK P',
    'US 9 / UK R',
    'US 10 / UK T',
    'US 11 / UK V',
    'US 12 / UK X',
    'US 13 / UK Z',
  ],
  'Diameter (mm)': [
    '14.1 mm',
    '14.9 mm',
    '15.7 mm',
    '16.5 mm',
    '17.3 mm',
    '18.1 mm',
    '18.9 mm',
    '19.8 mm',
    '20.6 mm',
    '21.4 mm',
    '22.2 mm',
  ],
};

const HAT_SIZES = {
  'US-UK': [
    'XS (6 7/8 - 7)',
    'S (7 - 7 1/8)',
    'M (7 1/8 - 7 1/4)',
    'L (7 1/4 - 7 3/8)',
    'XL (7 3/8 - 7 1/2)',
    '2XL (7 1/2 - 7 5/8)',
  ],
  'Centimeters': [
    '55 cm',
    '56 cm',
    '57 cm',
    '58 cm',
    '59 cm',
    '60 cm',
    '61 cm',
    '62 cm',
  ],
};

const BELT_SIZES = [
  '28-30 inches (71-76 cm)',
  '30-32 inches (76-81 cm)',
  '32-34 inches (81-86 cm)',
  '34-36 inches (86-91 cm)',
  '36-38 inches (91-97 cm)',
  '38-40 inches (97-102 cm)',
  '40-42 inches (102-107 cm)',
  '42-44 inches (107-112 cm)',
];

// Helper function to get sizes based on category and subcategory
List<String> getSizesForProduct(String category, String subCategory) {
  final subCategoryName = subCategory.split(' - ').last.trim();
  
  if (category == 'clothing') {
    if (subCategory.contains("Men's Wear")) {
      if (subCategoryName == 'Pants') {
        return MENS_CLOTHING_SIZES['Pants & Trousers']!;
      } else if (subCategoryName == 'Suits') {
        return MENS_CLOTHING_SIZES['Suits']!;
      } else {
        return MENS_CLOTHING_SIZES['Shirts & T-Shirts']!;
      }
    } else if (subCategory.contains("Women's Wear")) {
      if (subCategoryName == 'Pants' || subCategoryName == 'Skirts') {
        return WOMENS_CLOTHING_SIZES['Pants & Skirts']!;
      } else if (subCategoryName == 'Blouses') {
        return WOMENS_CLOTHING_SIZES['Blouses']!;
      } else {
        return WOMENS_CLOTHING_SIZES['Dresses & Tops']!;
      }
    }
  } else if (category == 'accessories') {
    if (subCategoryName == 'Rings' || subCategory.contains('Jewelry')) {
      return RING_SIZES['US-UK']!;
    } else if (subCategoryName == 'Hats') {
      return HAT_SIZES['US-UK']!;
    } else if (subCategoryName == 'Belts') {
      return BELT_SIZES;
    }
  } else if (subCategory.contains('Footwear') || 
            subCategoryName == 'Sneakers' || 
            subCategoryName == 'Formal Shoes' || 
            subCategoryName == 'Boots' || 
            subCategoryName == 'Sandals') {
    return SHOE_SIZES['US-EU-UK Men']!;
  }
  
  return [];
} 
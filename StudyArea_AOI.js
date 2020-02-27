
// create a polygon in a place of interest for this to run properly




var collection = ee.ImageCollection('COPERNICUS/S2')
    .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE',1))
    .filterDate('2017-07-01','2017-12-31')
    .filterBounds(geometry);
    
print(collection);

var imagelist = collection.toList(collection.size());

print(imagelist)

var img1 = imagelist.get(4)
var img2 = imagelist.get(7)

//print(img1)

var scene1 = ee.Image(img1);
var scene2 = ee.Image(img2);

print(scene1)
print(scene2)

var visParams = {bands: ['B4', 'B3', 'B2'],gain: '0.1, 0.1, 0.1',scale:20};
var visParams_NIR = {bands: ['B8', 'B4', 'B3'],gain: '0.1, 0.1, 0.1',scale:20};

//Map.setCenter( 15.324241,52.538423,  10); // Center on the Grand Canyon.
//Map.addLayer(scene,visParams,'RGB');
Map.addLayer(scene1,visParams_NIR,'NIR - 2017 09 25');
Map.addLayer(scene2,visParams_NIR,'NIR - 2017 11 01');

var min = collection.min();

// Select the red, green and blue bands.
//var result = min.select('B7', 'B5', 'B4');

//Map.addLayer(result, {gain: '0.1, 0.1, 0.1', scale:20},'working');
//Map.setCenter(5, 47, 4);

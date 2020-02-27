//Copied from: https://gis.stackexchange.com/questions/273658/performing-object-based-image-classification-in-google-earth-engine/289057#289057
//Written by Nicholas Clinton as a response


var imageCollection = ee.ImageCollection('USDA/NAIP/DOQQ');

var geometry = /* color: #0b4a8b */ee.Geometry.Polygon(
        [[[-121.89511299133301, 38.98496606984683],
          [-121.89511299133301, 38.909335196675435],
          [-121.69358253479004, 38.909335196675435],
          [-121.69358253479004, 38.98496606984683]]], null, false);

var cdl2016 = ee.Image('USDA/NASS/CDL/2016');

var bands = ['R', 'G', 'B', 'N']
var img = imageCollection
    .filterDate('2015-01-01', '2017-01-01')
    .filterBounds(geometry)
    .mosaic()
img = ee.Image(img).clip(geometry).divide(255).select(bands)
Map.centerObject(geometry, 13)
Map.addLayer(img, {gamma: 0.8}, 'RGBN', false)

var seeds = ee.Algorithms.Image.Segmentation.seedGrid(36);

// Run SNIC on the regular square grid.
var snic = ee.Algorithms.Image.Segmentation.SNIC({
  image: img, 
  size: 32,
  compactness: 5,
  connectivity: 8,
  neighborhoodSize:256,
  seeds: seeds
}).select(['R_mean', 'G_mean', 'B_mean', 'N_mean', 'clusters'], ['R', 'G', 'B', 'N', 'clusters'])

var clusters = snic.select('clusters')
Map.addLayer(clusters.randomVisualizer(), {}, 'clusters')
Map.addLayer(snic, {bands: ['R', 'G', 'B'], min:0, max:1, gamma: 0.8}, 'means', false)

// Compute per-cluster stdDev.
var stdDev = img.addBands(clusters).reduceConnectedComponents(ee.Reducer.stdDev(), 'clusters', 256)
Map.addLayer(stdDev, {min:0, max:0.1}, 'StdDev', false)

// Area, Perimeter, Width and Height
var area = ee.Image.pixelArea().addBands(clusters).reduceConnectedComponents(ee.Reducer.sum(), 'clusters', 256)
Map.addLayer(area, {min:50000, max: 500000}, 'Cluster Area', false)

var minMax = clusters.reduceNeighborhood(ee.Reducer.minMax(), ee.Kernel.square(1));
var perimeterPixels = minMax.select(0).neq(minMax.select(1)).rename('perimeter');
Map.addLayer(perimeterPixels, {min: 0, max: 1}, 'perimeterPixels');

var perimeter = perimeterPixels.addBands(clusters)
    .reduceConnectedComponents(ee.Reducer.sum(), 'clusters', 256);
Map.addLayer(perimeter, {min: 100, max: 400}, 'Perimeter size', false);

var sizes = ee.Image.pixelLonLat().addBands(clusters).reduceConnectedComponents(ee.Reducer.minMax(), 'clusters', 256)
var width = sizes.select('longitude_max').subtract(sizes.select('longitude_min')).rename('width')
var height = sizes.select('latitude_max').subtract(sizes.select('latitude_min')).rename('height')
Map.addLayer(width, {min:0, max:0.02}, 'Cluster width', false)
Map.addLayer(height, {min:0, max:0.02}, 'Cluster height', false)

var objectPropertiesImage = ee.Image.cat([
  snic.select(bands),
  stdDev,
  area,
  perimeter,
  width,
  height
]).float();

var training = objectPropertiesImage.addBands(cdl2016.select('cropland'))
    .updateMask(seeds)
    .sample(geometry, 5);
var classifier = ee.Classifier.randomForest(10).train(training, 'cropland')
Map.addLayer(objectPropertiesImage.classify(classifier), {min:0, max:254}, 'Classified objects')

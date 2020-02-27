
//Centering the map
Map.setCenter(21.025, 52.24, 15);
//Map.setOptions('satellite')


//Creating a point
var poi = ee.Geometry.Point(21.025, 52.24);

print(poi)

//Visualizing
//Map.addLayer(poi,{color: 'blue'},"Blue")
//Map.addLayer(poi,{color: 'green'},"Green")
//Map.addLayer(poi,{color: 'red'},"Red")

//Other examples
var multi = ee.Geometry.MultiPoint(21.026, 52.245, 21.027, 52.245, 21.028, 52.245);
print(multi)
Map.addLayer(multi,{color: 'blue'},"A blue line of points")
var lineStr = ee.Geometry.LineString([[21.026, 52.244], [21.027, 52.244], [21.028, 52.244]]);
print(lineStr)
Map.addLayer(lineStr,{color: 'red'},"A red line")
var rect = ee.Geometry.Rectangle(21.026, 52.242, 21.028,  52.243);
print(rect)
Map.addLayer(rect,{color: 'green'},"A green rectangle")






## [1.1.0] - 15/03/2023

- Merge pull request #159 from ignatz/null-safe_latlngbounds
- Merge pull request #156 from abdulmeLINK/master
- Merge pull request #154 from philipgiuliani/patch-1
- Merge pull request #152 from ignatz/master

## [1.0.2] - 10/02/2023

- Merge pull request #148 from ignatz/fast_traversal

## [1.0.1] - 11/10/2022

- Merge pull request #141 from hahrot/patch-1

## [0.5.4] - 15/08/2022

- Wait unspiderfy before to spiderfy another cluster

## [0.5.3] - 12/08/2022

- Fix lint errors

## [0.5.2] - 12/08/2022

- Merge pull request #132 from aytunch/null-check-bug
- Merge pull request #110 from Feynallein/master

## [0.5.1] - 11/08/2022

- Merge pull request #130 from RicardoRB/master
- Merge pull request #125 from appsup-dart/flicker-issue
- Merge pull request #112 from thoKling/master

## [0.5.0] - 28/06/2022

- #120 Bump flutter map 1.0.0

## [0.4.4] - 29/11/2021

- Center cluster when spiderfy. Spiderfy when press cluster and current zoom is equal to fitBoundsOptions max zoom

## [0.4.3] - 04/11/2021

- Fix #98: Loose marker alignment after upgrading library

## [0.4.2] - 25/10/2021

- #94 Support Marker rotate, rotateOrigin and rotateAlignment options

## [0.4.1] - 23/09/2021

- Upgrade to flutter_map_marker_popup v2.0.0 which now supports showing multiple
  popups at once. The default behaviour when using popups remains single-popup
  but some breaking changes in PopupController were required:

  - hidePopups -> hideAllPopups
  - hidePopupIfShowingFor -> hidePopupsOnlyFor
  - showPopup -> showPopupsOnlyFor

  If you wish to show multiple popups at once you will want to change the
  default MarkerTapBehavior, see the documentation in PopupMarkerLayerOptions.

## [0.4.0] - 21/06/2021

- Null safety update

## [0.3.5] - 27/05/2021

- Fix deprecate warning
- Added marker_cluster_layer_widget

## [0.3.4] - 02/03/2021

- #65 Ensure cluster is split when tapping it
- Upgrade flutter_map_marker_popup

## [0.3.3] - 25/01/2021

- Upgraded flutter_map

## [0.3.2] - 25/01/2021

- Added key so that states are preserved when map moves

## [0.3.1] - 31/08/2020

- Removed extras property to marker
- Added disableClusteringAtZoom property to MarkerClusterLayerOptions

## [0.3.0] - 25/08/2020

- Added extras property to marker

## [0.2.9] - 25/08/2020

- Upgraded flutter_map to 0.10.1+1

## [0.2.8] - 29/04/2019

- Added marker popup
- Added marker onClusterTap option
- Upgraded flutter_map to 0.9.0

## [0.2.7] - 08/02/2019

- Update support for latest flutter_map and add support for AndroidX #27

## [0.2.6] - 08/02/2019

- updated flutter_map

## [0.2.5] - 18/11/2019

- added animationsoptions
- #24 Add optional onTap callback for Markers

## [0.2.4] - 18/11/2019

- added analysis_options.yaml
- fix warnings

## [0.2.0] - 26/06/2019

- fix positions
- spiderfyCircleDistanceMultiplier to spiderfyCircleRadius

## [0.1.6] - 26/06/2019

- fix circle spiferfy
- splitted spiderfyDistanceMultiplier to spiderfyCircleDistanceMultiplier and spiderfySpiralDistanceMultiplier
- added to gesturedetector behavior opaque
- spiderfy marker animation starts to cluster point
- added anchorpos to cluster in example

## [0.1.5] - 20/06/2019

- setState issue fixed ( #4 setState not supported )
- added example with marker that change position

## [0.1.4] - 17/06/2019

- MarkerClusterGroupPlugin to MarkerClusterPlugin
- MarkerClusterGroupLayerOptions to MarkerClusterLayerOptions
- maxZoom and minZoom not required ( #2 MapOptions.minZoom required )
- refresh when change markers ( #4 setState not supported )
- fix when spiderfy

## [0.1.3] - 07/06/2019

- flutter_map version 0.5.5+2
- options added anchorPos
- removed removeOutsideVisibleBound

## [0.1.2] - 07/06/2019

- added option showPolygon
- polygon line are all cluster's markers and not cluster's child

## [0.1.1] - 06/06/2019

- polygon under clusters and markers

## [0.1.0] - 06/06/2019

- added some tests and configurated travis ci

## [0.0.1] - 06/06/2019

- inital release

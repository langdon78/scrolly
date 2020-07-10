import UIKit
import Track

func display(track: Track<Double>) {
    print("-----------------------------")
    print("Current Interval: \(track.interval.start) to \(aTrack.interval.finish)")
    print("Current Location: \(track.currentLocation)")
    print("Relative Position: \(track.position)")
    print("Relative Location: \(track.relativeLocation)")
    print("=============================")
}
/*:
 ## Interval
 #### Two points representing a line
 */
let nextInterval = Track.Interval(start: 500, finish: 750)
nextInterval.increasing
nextInterval.decreasing
nextInterval.mid
nextInterval.distance
/*:
## Track
#### A data structure representing a linear relationship between a point and two other points (interval)
*/
var aTrack = Track(currentLocation: 10, start: 20, finish: 200)
display(track: aTrack)

aTrack.updateCurrentLocation(with: 140)
display(track: aTrack)

aTrack.updateCurrentLocation(with: 240)
display(track: aTrack)
/*:
 ### Conversion and Relocation
 */
let add200 = aTrack.convert { track in
    return { interval in
        interval.start + 200
    }
}
add200(nextInterval)

aTrack.updateCurrentLocation(with: 150)
display(track: aTrack)
print("The current location is \((aTrack.percentIncreasing * 100).rounded())% through the interval")

let newPoint = aTrack.relocateProportionately(to: nextInterval)
print("aTrack location in interval \(nextInterval.start) to \(nextInterval.finish) is \(newPoint)")


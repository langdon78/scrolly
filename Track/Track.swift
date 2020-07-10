//
//  LinearTransition.swift
//  scrolly
//
//  Created by James Langdon on 6/28/20.
//  Copyright © 2020 corporatelangdon. All rights reserved.
//

import Foundation

public typealias Locator<Point: BinaryFloatingPoint> = (Track<Point>.Interval) -> Point
public typealias Movement<Point: BinaryFloatingPoint> = (Track<Point>) -> Locator<Point>

public struct Track<Point: BinaryFloatingPoint> {
    public var currentLocation: Point
    public var interval: Interval
    
    public init(currentLocation: Point = 0.0, interval: Interval) {
        self.currentLocation = currentLocation
        self.interval = interval
    }
    
    public init(currentLocation: Point = 0.0, start: Point, finish: Point) {
        self.init(currentLocation: currentLocation, interval: Interval(start: start, finish: finish))
    }
}

//MARK: - Data structures
public extension Track {
    
    enum RelativePosition {
        case before
        case after
        case inside
    }

    struct Interval {
        public var start: Point
        public var finish: Point
        
        public var distance: Point {
            return max - min
        }
        public var singular: Bool {
            start == finish
        }
        public var increasing: Bool {
            finish > start
        }
        public var decreasing: Bool {
            finish < start
        }
        public var min: Point {
            increasing ? start : finish
        }
        public var max: Point {
            increasing ? finish : start
        }
        public var mid: Point {
            distance / 2
        }
        
        public init(start: Point, finish: Point) {
            self.start = start
            self.finish = finish
        }
    }
    
}

//MARK: - Computed properties
public extension Track {
    
    var position: RelativePosition {
        if increasing ? currentLocation < interval.min : currentLocation > interval.max {
            return .before
        } else if increasing ? currentLocation > interval.max : currentLocation < interval.min {
            return .after
        } else {
            return .inside
        }
    }
    var relativeLocation: Point {
        switch position {
        case .after: return interval.finish
        case .before: return interval.start
        case .inside: return currentLocation
        }
    }
    var increasing: Bool {
        interval.increasing
    }
    var distanceFromStart: Point {
        increasing ? relativeLocation - interval.min : interval.max - relativeLocation
    }
    var percentIncreasing: Point {
        guard !interval.singular else { return 0 }
        return distanceFromStart / interval.distance
    }
    var percentDecreasing: Point {
        1 - percentIncreasing
    }
    
}

//MARK: - Location and conversion
public extension Track {
    
    static func locate(_ currentLocation: Point, in interval: Interval) -> Point {
        let transition = Track(currentLocation: currentLocation, interval: interval)
        return transition.relativeLocation
    }
    
    func convert(_ apply: @escaping Movement<Point>) -> Locator<Point> {
        { interval in
            let transition = Track(currentLocation: self.currentLocation, interval: interval)
            return apply(transition)(interval)
        }
    }
    
    func relocateProportionately(to interval: Interval) -> Point {
        let percentage = convertToPercent(isIncreasing: interval.increasing)
        return (percentage * interval.distance) + interval.min
    }
    
    mutating func updateCurrentLocation(with value: Point) {
        currentLocation = value
    }
    
    func convertToPercent(isIncreasing: Bool) -> Point {
        Point(isIncreasing ? percentIncreasing : percentDecreasing)
    }
    
}

//MARK: - Action handlers
public extension Track {
    
    func execute(before: (() -> Void)? = nil, after: (() -> Void)? = nil, during: (() -> Void)? = nil) {
        switch position {
        case .before: before?()
        case .after: after?()
        case .inside: during?()
        }
    }
    
    @discardableResult func executeDuring(_ action: (() -> Void)? = nil) -> Track<Point> {
        if case .inside = position {
            action?()
        }
        return self
    }
    
    @discardableResult func executeBefore(_ action: (() -> Void)? = nil) -> Track<Point> {
        if case .before = position {
            action?()
        }
        return self
    }
    
    @discardableResult func executeAfter(_ action: (() -> Void)? = nil) -> Track<Point> {
        if case .after = position {
            action?()
        }
        return self
    }
    
}

//MARK: - Fading
public extension Track {
    
    static func applyFadeIn(from start: Point, to finish: Point) -> (Self) -> Point {
        return { transition in
            self.applyFade(in: transition, from: start, to: finish, fadeOut: false)
        }
    }
    
    static func applyFadeOut(from start: Point, to finish: Point) -> (Self) -> Point {
        return { transition in
            self.applyFade(in: transition, from: start, to: finish)
        }
    }
    
    private static func applyFade(in transition: Self, from start: Point, to finish: Point, fadeOut: Bool = true) -> Point {
        let interval = Interval(start: start, finish: finish)
        return transition.convert { transition in
            return { interval in
                if fadeOut {
                    return transition.percentDecreasing
                } else {
                    return transition.percentIncreasing
                }
            }
        }(interval)
    }
    
}

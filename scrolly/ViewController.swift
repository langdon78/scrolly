//
//  ViewController.swift
//  scrolly
//
//  Created by James Langdon on 5/26/20.
//  Copyright © 2020 corporatelangdon. All rights reserved.
//

import UIKit

let scrollNotification = Notification.Name(rawValue: "scrolly")
let stopNotification = Notification.Name(rawValue: "stop")

class ViewController: UIViewController {
    
    //MARK: IBOutlets
    @IBOutlet weak var collapseableView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var greetingButton: UIButton!
    @IBOutlet weak var someDataLabel: UILabel!
    @IBOutlet weak var collapseableViewHeight: NSLayoutConstraint!
    @IBOutlet var menuItems: [UIView]!
    @IBOutlet weak var labelLead: NSLayoutConstraint!
    
    //MARK: Constants
    static let maxLabelLead: CGFloat = 300
    static let minLabelLead: CGFloat = 40
    static let maxImageHeight: CGFloat = 320
    static let minImageHeight: CGFloat = 80
    static let maxCollapseableViewHeight: CGFloat = 560
    static let minCollapseableViewHeight: CGFloat = 80
    static var menuFadeOutStart: CGFloat = maxCollapseableViewHeight - 80
    static var menuFadeOutEnd: CGFloat = maxImageHeight
    static let greetingFadeStart: CGFloat = 280
    static let greetingFadeEnd: CGFloat = 200
    static let offsetKey = "offset"
    static let scrollableKey = "scrollable"
    
    //MARK: Tracks
    var collapseableViewTrack = Track(start: maxCollapseableViewHeight, finish: minCollapseableViewHeight) {
        didSet {
            collapseableViewHeight.constant = collapseableViewTrack.relativeLocation
        }
    }
    var imageTrack = Track(start: maxImageHeight, finish: minImageHeight) {
        didSet {
            imageHeightConstraint.constant = imageTrack.relativeLocation
            greetingButton.alpha = greetingFade(imageTrack)
            self.menuItems.forEach { $0.alpha = self.menuFade(self.collapseableViewTrack) }
        }
    }
    var labelTrack = Track(start: maxLabelLead, finish: minLabelLead) {
        didSet {
            labelLead.constant = labelTrack.relativeLocation
        }
    }
    
    var menuFade = Track<CGFloat>.applyFadeOut(from: menuFadeOutStart,
                                 to: menuFadeOutEnd)
    
    var greetingFade = Track<CGFloat>.applyFadeIn(from: greetingFadeStart,
                                        to: greetingFadeEnd)

    
    //MARK: Data source
    lazy var items: [String] = {
        (1...30).map { "Important item \($0)" }
    }()
    
    //MARK: Scroll state
    var isScrollable = false
    var lastScrollDirectionUp = true
    var oldCollapseableViewHeight: CGFloat = 0.0
    
    //MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Scroll notifications
        NotificationCenter.default.addObserver(forName: scrollNotification, object: nil, queue: .main) { notification in
            guard let userInfo = notification.userInfo,
                let offset = userInfo[Self.offsetKey] as? CGFloat else { return }
            self.didScroll(with: offset)
        }
        
        NotificationCenter.default.addObserver(forName: stopNotification, object: nil, queue: .main) { notification in
            guard let userInfo = notification.userInfo,
                let scrollable = userInfo[Self.scrollableKey] as? Bool else { return }
            self.isScrollable = scrollable
            
        }
    }
    
    //MARK: Scroll handling
    private func didScroll(with offset: CGFloat) {
        NotificationCenter.default.post(name: stopNotification, object: nil, userInfo: [Self.scrollableKey: false])
        
        let updatedCollapseableViewHeight = collapseableViewHeight.constant - offset
        collapseableViewTrack.updateCurrentLocation(with: updatedCollapseableViewHeight)
        imageTrack.updateCurrentLocation(with: updatedCollapseableViewHeight)
        
        let labelTrackPosition = imageTrack.relocateProportionately(to: labelTrack.interval)
        labelTrack.updateCurrentLocation(with: labelTrackPosition)
        
        executeTrackActions()
    }
    
    private func executeTrackActions() {
        imageTrack.executeAfter {
            NotificationCenter.default.post(name: stopNotification, object: nil, userInfo: [Self.scrollableKey: true])
        }
    }
    
    private func didScrollUp(to newHeight: CGFloat) -> Bool {
        var didScrollUp = true
        if newHeight <= oldCollapseableViewHeight {
            didScrollUp = false
        }
        oldCollapseableViewHeight = newHeight
        return didScrollUp
    }
    
    //MARK: IBActions
    @IBAction func buttonTapped(_ sender: UIButton) {
        let bottom = false
        snap(to: bottom)
    }
    
}

//MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
    
}

//MARK: - UITableViewDelegate methods
extension ViewController: UITableViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        NotificationCenter.default.post(name: scrollNotification, object: nil, userInfo: [Self.offsetKey: scrollView.contentOffset.y])

        let newHeight = self.collapseableViewHeight.constant - scrollView.contentOffset.y
        lastScrollDirectionUp = didScrollUp(to: newHeight)
        
        if !isScrollable {
            scrollView.contentOffset.y = 0 // block scroll view
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        snapToEdge()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        snapToEdge()
    }
    
}

//MARK: - Handle snapping table view to top/bottom on scroll
extension ViewController {
    
    func snapToEdge() {
        if !isScrollable {
            snap(to: lastScrollDirectionUp)
        }
    }
    
    func snap(to top: Bool) {
        let imageHeight = top ? Self.minImageHeight : Self.maxImageHeight
        let collapseableViewHeight = top ? Self.minCollapseableViewHeight : Self.maxCollapseableViewHeight
        let labelLead = top ? Self.minLabelLead : Self.maxLabelLead
        let menuFade: CGFloat = top ? 0.0 : 1.0
        let greetingFade: CGFloat = top ? 1.0 : 0.0
        
        UIView.animate(withDuration: 0.25) {
            self.imageHeightConstraint.constant = imageHeight
            self.collapseableViewHeight.constant = collapseableViewHeight
            self.labelLead.constant = labelLead
            self.isScrollable = top
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            self.view.layoutIfNeeded()
        }
        self.menuItems.forEach { $0.alpha = menuFade }
        self.greetingButton.alpha = greetingFade
    }
    
}

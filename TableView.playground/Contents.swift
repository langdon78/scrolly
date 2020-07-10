//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport

class MyViewController : UIViewController {
    var tableView = UITableView()
    lazy var tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 150)
    let testData = (1...30).map { "Test Data \($0)" }
    
    override func loadView() {
        super.loadView()
        
        let view = UIView()
        view.backgroundColor = .lightGray

        let label = UILabel()
        label.frame = CGRect(x: 150, y: 200, width: 200, height: 20)
        label.text = "Hello World!"
        label.textColor = .black
        
        view.addSubview(label)
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        (tableView as UIScrollView).delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        layoutViews()
    }
    
    func layoutViews() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableViewHeightConstraint
        ])
    }
}

extension MyViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return testData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = testData[indexPath.row]
        return cell
    }
}

extension MyViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print(scrollView.contentOffset.y)
        
//        tableViewHeightConstraint.constant += scrollView.contentOffset.y
//        scrollView.contentOffset.y = 0 // block scroll view
    }
}
    
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()

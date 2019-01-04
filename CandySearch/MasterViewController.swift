import UIKit
import SwiftElasticSearch

class MasterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  
  // MARK: - Properties
  @IBOutlet var tableView: UITableView!
  @IBOutlet var searchFooter: SearchFooter!
  
  var detailViewController: DetailViewController? = nil
  var candies = [Candy]()
  var filteredCandies = [Candy]()
  let elasticClient = Client.init(app: "new_movie_app", credentials: "4oPCtg8U6:3470e2d8-6559-4d8d-9635-400cc6a4b74c")
  let searchController = UISearchController(searchResultsController: nil)
  
  // MARK: - View Setup
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Setup the Search Controller
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.placeholder = "Search Books"
    navigationItem.searchController = searchController
    definesPresentationContext = true
    
    // Setup the Scope Bar
   // searchController.searchBar.scopeButtonTitles = ["All", "Chocolate", "Hard", "Other"]
   // searchController.searchBar.delegate = self
    
    // Setup the search footer
    tableView.tableFooterView = searchFooter
    candies = []
    if let path = Bundle.main.path(forResource: "data", ofType: "json") {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            let x = jsonResult as! [Any]
            for data in x {
                let data = data as! Dictionary<String, Any>
                let source = data["_source"]
                let xyz = source as! Dictionary<String, Any>
                let year = xyz["original_publication_year"]
                let title = xyz["original_title"]
                let url = xyz["image"]
                let a = year!
                let b = title!
                let c = url!
                candies.append(Candy(category: a as? String ?? "", name: b as? String ?? "", url: c as? String ?? ""))
            }
            
        } catch {
            // handle error
            print("err")
        }
    }
    
    if let splitViewController = splitViewController {
      let controllers = splitViewController.viewControllers
      detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    if splitViewController!.isCollapsed {
      if let selectionIndexPath = tableView.indexPathForSelectedRow {
        tableView.deselectRow(at: selectionIndexPath, animated: animated)
      }
    }
    super.viewWillAppear(animated)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: - Table View
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if isFiltering() {
      searchFooter.setIsFilteringToShow(filteredItemCount: filteredCandies.count, of: candies.count)
      return filteredCandies.count
    }
    
    searchFooter.setNotFiltering()
    return candies.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    let candy: Candy
    if isFiltering() {
      candy = filteredCandies[indexPath.row]
    } else {
      candy = candies[indexPath.row]
    }
    cell.textLabel!.text = candy.name
    cell.detailTextLabel!.text = candy.category
    return cell
  }
  
  // MARK: - Segues
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showDetail" {
      if let indexPath = tableView.indexPathForSelectedRow {
        let candy: Candy
        if isFiltering() {
          candy = filteredCandies[indexPath.row]
        } else {
          candy = candies[indexPath.row]
        }
        let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
        controller.detailCandy = candy
        controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        controller.navigationItem.leftItemsSupplementBackButton = true
      }
    }
  }
  
  // MARK: - Private instance methods
  
  func filterContentForSearchText(searchJson: [Any]) {
    print(searchJson)
    var newCandies = [Candy]()
    newCandies = []
    for data in searchJson {
        let data = data as! Dictionary<String, Any>
        let source = data["_source"]
        let xyz = source as! Dictionary<String, Any>
        let year = xyz["original_publication_year"]
        let title = xyz["original_title"]
        let url = xyz["image"]
        let a = year!
        let b = title!
        let c = url!
        newCandies.append(Candy(category: a as? String ?? "", name: b as? String ?? "", url: c as? String ?? ""))
    }
    filteredCandies = newCandies
    tableView.reloadData()
  }
  
  func searchBarIsEmpty() -> Bool {
    return searchController.searchBar.text?.isEmpty ?? true
  }
  
  func isFiltering() -> Bool {
    let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
    return searchController.isActive && (!searchBarIsEmpty() || searchBarScopeIsFiltering)
  }
}
//
//extension MasterViewController: UISearchBarDelegate {
//  // MARK: - UISearchBar Delegate
//  func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
//    filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
//  }
//}
var finalJson:[Any] = []
extension MasterViewController: UISearchResultsUpdating {
  // MARK: - UISearchResultsUpdating Delegate
  func updateSearchResults(for searchController: UISearchController) {
    //let searchBar = searchController.searchBar
//    let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
    let body:[String:Any] = [
        "query": [
            "match_phrase_prefix": [
                 "original_title" : [
                    "query" : searchController.searchBar.text!,
                    "slop":  50
                ]
            ]
        ]
    ]

    
    elasticClient.search(type: "good-books-ds" , body: body) { (json,response, error) in
        var json = json as! Dictionary<String, Any>
        json = json["hits"] as? Dictionary<String, Any> ?? [:]
        let a = json
        let b = a["hits"] ?? [:]
        finalJson = b as? [Any] ?? []
            //print(finalJson)
    }
    print(searchController.searchBar.text!)
    filterContentForSearchText(searchJson: finalJson)
    filterContentForSearchText(searchJson: finalJson)

  }
}

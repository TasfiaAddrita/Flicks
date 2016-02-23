//
//  MoviesViewController.swift
//  Flicks
//
//  Created by Tasfia Addrita on 1/10/16.
//  Copyright © 2016 Tasfia Addrita. All rights reserved.
//

import UIKit
import AFNetworking
import KVNProgress

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var networkErrorView: UIView!
    
    var movies: [NSDictionary]?
    var filteredData : [NSDictionary]!
    var endpoint : String!
    var refreshControl: UIRefreshControl?
    var configuration: KVNProgressConfiguration = KVNProgressConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Flicks"
        
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        filteredData = movies
        
        networkErrorView.hidden = true
        
        KVNProgress.showWithStatus("", onView: self.view)
        
        // pull to refresh
        refreshControl = UIRefreshControl()
        refreshControl?.backgroundColor = UIColor(red: 64, green: 64, blue: 64, alpha: 0)
        refreshControl?.tintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        refreshControl!.addTarget(self, action: "onRefresh:", forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl!, atIndex: 0)
        
        networkRequest()
        
        let textFieldInsideSearchBar = searchBar.valueForKey("searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = UIColor.whiteColor()
        
        // attempt to hide keyboard when user taps on anything; it works but user must put in more effort to tap on cell
        let gestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "hideKeyboard")
        self.view.addGestureRecognizer(gestureRecognizer)
        
        let gestureRecognizer2: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "networkErrorReboot")
        self.networkErrorView.addGestureRecognizer(gestureRecognizer2)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let filteredData = filteredData {
            return filteredData.count
        } else {
            return 0
        }
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        let movie = filteredData[indexPath.row]
        
        let title = movie["title"] as! String
        cell.titleLabel.text = title
        
        let overview = movie["overview"] as! String
        cell.overviewLabel.text = overview
        
        let placeHolderImage = UIImage(named: "noPoster.jpg")
        if let posterPath = movie["poster_path"] as? String {
            fadeInImage(posterPath, cell: cell)
        } else {
            cell.posterView.image = placeHolderImage
        }
        
        return cell
        
    }
    
    /*----------------------------------------
    * All images fade in as they are loading.    
    -----------------------------------------*/
    
    func fadeInImage(posterPath : String, cell : MovieCell) {
        
        let baseUrl = "http://image.tmdb.org/t/p/w500"
        let imageUrl = baseUrl + posterPath
        let imageRequest = NSURLRequest(URL: NSURL(string: imageUrl)!)
        
        cell.posterView.setImageWithURLRequest(
            imageRequest,
            placeholderImage: nil,
            success: { (imageRequest, imageResponse, image) -> Void in
                    cell.posterView.alpha = 0.0
                    cell.posterView.image = image
                    UIView.animateWithDuration(0.3, animations: { () -> Void in
                        cell.posterView.alpha = 1.0
                    })
            },
            failure: { (imageRequest, imageResponse, error) -> Void in
                // do something for the failure condition
        })
    }
    
    /*----------------------------------------
     * Search bar function
    -----------------------------------------*/
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filteredData = searchText.isEmpty ? movies : movies!.filter({(movie: NSDictionary) -> Bool in
            return (movie["title"] as! String).rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
        })
        
        self.tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.view.endEditing(true)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.view.endEditing(true)
    }
    
    func hideKeyboard() {
        if searchBar.isFirstResponder() {
            self.view.endEditing(true)
        }
    }
    
    /*----------------------------------------
     * Refresh functions
    -----------------------------------------*/
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    func onRefresh(refreshControl: UIRefreshControl) {
        networkRequest()
        refreshControl.endRefreshing()
    }
    
    /*----------------------------------------
     * Network Request function
    -----------------------------------------*/

    func networkRequest() {
        
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string:"https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        
        self.delay(1, closure: {KVNProgress.dismiss()})
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            NSLog("response: \(responseDictionary)")
                            
                            //self.delay(1, closure: {KVNProgress.dismiss()})
                            
                            self.movies = (responseDictionary["results"] as? [NSDictionary])
                            self.filteredData = self.movies
                            self.tableView.reloadData()
                    }
                }
                if error != nil {
                    self.networkErrorView.hidden = false
                }
        });
        task.resume()
        
    }
    
    func networkErrorReboot() {
        networkRequest()
        networkErrorView.hidden = true
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPathForCell(cell)
        let movie = movies![indexPath!.row]
        
        let detailViewController = segue.destinationViewController as! DetailViewController
        detailViewController.movie = movie
    }
}

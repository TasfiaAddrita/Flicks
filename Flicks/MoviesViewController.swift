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
    
    var movies: [NSDictionary]?
    var filteredData : [NSDictionary]!
    
    var refreshControl: UIRefreshControl?
    var configuration: KVNProgressConfiguration = KVNProgressConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        filteredData = movies
        
        KVNProgress.showWithStatus("", onView: self.view)
        
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: "onRefresh", forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl!, atIndex: 0)
        
        networkRequest()
        
        // Do any additional setup after loading the view.
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
        let overview = movie["overview"] as! String
        
        let placeHolderImage = UIImage(named: "noPoster.jpg")
        
        if let posterPath = movie["poster_path"] as? String {
            let baseUrl = "http://image.tmdb.org/t/p/w500"
            let imageUrl = NSURL(string: baseUrl + posterPath)
            cell.posterView.setImageWithURL(imageUrl!)
            
        }
        else {
            cell.posterView.image = placeHolderImage
        }
        
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        print("row \(indexPath.row)")
        return cell
        
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
    
    func onRefresh() {
        delay(2, closure: {
            self.refreshControl!.endRefreshing()
        })
    }
    
    /*----------------------------------------
     * Network Request function
    -----------------------------------------*/

    func networkRequest() {
        
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string:"https://api.themoviedb.org/3/movie/now_playing?api_key=\(apiKey)")
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            NSLog("response: \(responseDictionary)")
                            
                            self.delay(2, closure: {KVNProgress.dismiss()})
                            
                            self.movies = (responseDictionary["results"] as? [NSDictionary])
                            self.filteredData = self.movies
                            self.tableView.reloadData()
                    }
                }
        });
        task.resume()
        
    }
    
    // removes keyboard from screen after user is done typing in the searchBar
    @IBAction func onTap(sender: AnyObject) {
        view.endEditing(true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

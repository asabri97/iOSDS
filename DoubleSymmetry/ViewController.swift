//
//  ViewController.swift
//  DoubleSymmetry
//
//  Created by Abrish Sabri on 21/12/19.
//  Copyright © 2019 Abrish Sabri. All rights reserved.
//

import UIKit
import Alamofire
import ObjectMapper
import Kingfisher




struct CurrentTrack:Codable{
    var title: String?
    var artwork_url: String?
    
}

struct Session: Codable {
    var name: String?
    var listener_count: Int?
    var genres: [String]?
    var current_track: CurrentTrack?
   
}


extension UIImageView{
    func setImageFromURL(url:String){
        let url = URL(string: url)
        let processor = DownsamplingImageProcessor(size: self.frame.size)
                     >> RoundCornerImageProcessor(cornerRadius: 0)
        self.kf.indicatorType = .activity
        self.kf.setImage(
            with: url,
            placeholder: UIImage(named: "placeholderImage"),
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(1)),
                .cacheOriginalImage
            ])
        {
            result in
            switch result {
            case .success(let value):
                print("Task done for: \(value.source.url?.absoluteString ?? "")")
            case .failure(let error):
                print("Job failed: \(error.localizedDescription)")
            }
        }
    }
}
class MockUpCell: UICollectionViewCell {
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
}

class ViewController: UIViewController,UISearchBarDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    var searchBarActive:Bool = false
    var searchBarBoundsY:CGFloat?
    var searchBar:UISearchBar?
    var refreshControl:UIRefreshControl?
    var sessionList : [Session] = []
    var activityView:UIActivityIndicatorView?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getMockRequestApi()
        self.addSearchBar()
        activityView = UIActivityIndicatorView(style: .whiteLarge)
        activityView?.center = self.view.center
        activityView?.startAnimating()
        activityView?.color = UIColor.black
        activityView?.hidesWhenStopped = true
        self.view.addSubview(activityView!)
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        tap.numberOfTapsRequired = 1;
        self.view.addGestureRecognizer(tap)
        // Do any additional setup after loading the view.
    }
    
    
    
    
    
    // AutoHide Keyboard when tap on screen
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        // handling code
        self.view.endEditing(true);
    }
    
    
    func getMockRequestApi()  {
        self.activityView?.startAnimating()
        let url = "http://www.mocky.io/v2/5df79a3a320000f0612e0115"
        Alamofire.request(url, method: .get, encoding: JSONEncoding.default)
            .responseJSON { response in

                switch response.result {
                case .success(let json):
                    print(json)
                    let dictRes = json as? [String:Any]
                    let dictData = dictRes?["data"] as? [String:Any]
                    let arrSession = dictData?["sessions"] as? [[String:Any]] ?? []
                    let sessionList : [Session] = []
                    for sessionObj in arrSession{
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: sessionObj, options: .prettyPrinted)
                           
                            let session = try! JSONDecoder().decode(Session.self, from: jsonData)
                            // here "jsonData" is the dictionary encoded in JSON data
                            self.sessionList.append(session);
                            let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
                            // here "decoded" is of type `Any`, decoded from JSON data

                        } catch {
                            print(error.localizedDescription)
                        }
                      
                    }
                    
                    //let sessionList = Mapper<Session>().mapArray(JSONArray: arrSession)
                 //   self.sessionList.append(sessionList);
                    self.sessionList.append(contentsOf: sessionList);
                    DispatchQueue.main.async {
                        self.activityView?.stopAnimating()
                        self.collectionView.reloadData();
                   }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.activityView?.stopAnimating()
                        self.showAlert(title: "CollectionView", message: error.localizedDescription)
                    }
                }
        }
    }
    
    func showAlert(title:String, message:String) {
        let alert = UIAlertController(title:title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler:nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func addSearchBar(){
        if self.searchBar == nil{
            self.searchBarBoundsY = (self.navigationController?.navigationBar.frame.size.height)! + UIApplication.shared.statusBarFrame.size.height

            self.searchBar = UISearchBar(frame: CGRect(x: 0,y: self.searchBarBoundsY!, width: UIScreen.main.bounds.size.width, height: 44))
            self.searchBar!.searchBarStyle       = .minimal
            self.searchBar!.tintColor            = UIColor.white
            self.searchBar!.barTintColor         = UIColor.white
            self.searchBar!.delegate             =  self;
            self.searchBar!.placeholder          = "search here";

           // self.addObservers()
        }
        
        if !self.searchBar!.isDescendant(of: self.view){
            self.view .addSubview(self.searchBar!)
        }
    }
    
    func addRefreshControl(){
        if (self.refreshControl == nil) {
            self.refreshControl            = UIRefreshControl()
            self.refreshControl?.tintColor = UIColor.white
            self.refreshControl?.addTarget(self, action: "refreashControlAction", for: .valueChanged)
        }
        if !self.refreshControl!.isDescendant(of: self.collectionView!) {
            self.collectionView!.addSubview(self.refreshControl!)
        }
    }
    func cancelSearching(){
           self.searchBarActive = false
           self.searchBar!.resignFirstResponder()
           self.searchBar!.text = ""
       }
    
    func refreashControlAction(){
        self.cancelSearching()
        self.collectionView?.reloadData()
        self.refreshControl?.endRefreshing()
    

    }
    
    // MARK: Search Delegate Methods
    func filterContentForSearchText(searchText:String){
        if(searchText == ""){
            self.sessionList = [];
            self.getMockRequestApi()
        }else{
            self.sessionList = self.sessionList.filter { (session) -> Bool in
                ((session.current_track?.title!.contains(searchText)) == true)
            }
            self.collectionView.reloadData()
        }
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filterContentForSearchText(searchText: searchText)
        // user did type something, check our datasource for text that looks the same
        if searchText.count > 0 {
            // search and reload data source
            self.searchBarActive    = true
            
            self.collectionView?.reloadData()
        }else{
            // if text lenght == 0
            // we will consider the searchbar is not active
            self.searchBarActive = false
            self.collectionView?.reloadData()
        }

    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self .cancelSearching()
        
        self.collectionView?.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBarActive = true
        self.view.endEditing(true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // we used here to set self.searchBarActive = YES
        // but we'll not do that any more... it made problems
        // it's better to set self.searchBarActive = YES when user typed something
        self.searchBar!.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        // this method is being called when search btn in the keyboard tapped
        // we set searchBarActive = NO
        // but no need to reloadCollectionView
        self.searchBarActive = false
        self.searchBar!.setShowsCancelButton(false, animated: false)
    }
}



extension ViewController: UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout{
   
    
   
    
    //MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       
        return self.sessionList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MockUpCell", for: indexPath) as! MockUpCell

        let urlString = sessionList[indexPath.row].current_track?.artwork_url ?? "";
        cell.imgView.setImageFromURL(url: urlString)
        cell.imgView.clipsToBounds = true
        cell.lblTitle.text = sessionList[indexPath.row].current_track?.title ?? "";
       
        return cell
    }
    
    
    
    
     //MARK: UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize{
        return CGSize(width: (self.collectionView.frame.size.width-20)/2, height: (self.collectionView.frame.size.width)/2)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if(self.searchBarActive == false){
            if indexPath.row == self.sessionList.count-1   {
                self.getMockRequestApi()
            }
        }
        
    }
    func collectionView( _ collectionView: UICollectionView,
                         layout collectionViewLayout: UICollectionViewLayout,
                         insetForSectionAt section: Int) -> UIEdgeInsets{
        return UIEdgeInsets(top: self.searchBar!.frame.size.height, left: 0, bottom: 0, right: 0);
    }
    
}

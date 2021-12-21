//
//  ViewController.swift
//  PodcastSearchPrototype
//
//  Created by Ezequiel Scaruli on 20/12/21.
//  
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private var podcasts = [[String: Any]]()
    private var favoriteIds = Set<Int>()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Search podcasts"

        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController

        tableView.dataSource = self
        tableView.delegate = self
    }

}

// MARK: UISearchResultsUpdating

extension ViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController
                .searchBar
                .text?
                .replacingOccurrences(of: " ", with: "+")
                .lowercased(),
              !searchText.isEmpty
        else {
            podcasts = []
            tableView.reloadData()
            return
        }

        let url = URL(string: "https://itunes.apple.com/search?term=\(searchText)&limit=15&entity=podcast")!
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, _, error in
            if error == nil,
               let safeData = data,
               let payload = try? JSONSerialization.jsonObject(with: safeData, options: []) as? [String: Any],
               let parsedPodcasts = payload["results"] as? [[String: Any]] {
                self.podcasts = parsedPodcasts
            } else {
                self.podcasts = []
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        task.resume()
    }

}

// MARK: UITableViewDataSource

extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return podcasts.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let podcast = podcasts[indexPath.row]

        // Text
        cell.textLabel?.text = podcast["trackName"] as? String

        // Image
        if let imageUrlString = podcast["artworkUrl60"] as? String {
            let imageUrl = URL(string: imageUrlString)!
            let imageTask = URLSession.shared.dataTask(with: URLRequest(url: imageUrl)) { data, _, error in
                let cellImage: UIImage?
                if error == nil,
                   let safeData = data,
                   let image = UIImage(data: safeData) {
                    cellImage = image
                } else {
                    cellImage = nil
                }
                DispatchQueue.main.async {
                    cell.imageView?.image = cellImage
                }
            }
            imageTask.resume()
        }

        // Accessory type
        if let podcastId = podcast["trackId"] as? Int, favoriteIds.contains(podcastId) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        cell.selectionStyle = .none
        return cell
    }

}

// MARK: UITableViewDelegate

extension ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let podcastId = podcasts[indexPath.row]["trackId"] as? Int,
              let cell = tableView.cellForRow(at: indexPath)
        else { return }
        if favoriteIds.contains(podcastId) {
            favoriteIds.remove(podcastId)
            cell.accessoryType = .none
        } else {
            favoriteIds.insert(podcastId)
            cell.accessoryType = .checkmark
        }
    }

}

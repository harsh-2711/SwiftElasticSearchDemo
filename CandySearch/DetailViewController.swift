import UIKit

class DetailViewController: UIViewController {
  
  @IBOutlet weak var detailDescriptionLabel: UILabel!
  @IBOutlet weak var candyImageView: UIImageView!
  
  var detailCandy: Candy? {
    didSet {
      configureView()
    }
  }
  
  func configureView() {
    if let detailCandy = detailCandy {
      if let detailDescriptionLabel = detailDescriptionLabel, let candyImageView = candyImageView {
        detailDescriptionLabel.text = detailCandy.name
        let url = URL(string: detailCandy.url)
        let data = try? Data(contentsOf: url!)
        candyImageView.image = UIImage(data: data!)
        title = detailCandy.category
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureView()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
}


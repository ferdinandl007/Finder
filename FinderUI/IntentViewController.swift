//
//  IntentViewController.swift
//  FinderUI
//
//  Created by Ferdinand Lösch on 25/11/2018.
//  Copyright © 2018 Ferdinand Lösch. All rights reserved.
//


import IntentsUI





// As an example, this extension's Info.plist has been configured to handle interactions for INSendMessageIntent.
// You will want to replace this or add other intents as appropriate.
// The intents whose interactions you wish to handle must be declared in the extension's Info.plist.

// You can test this example integration by saying things to Siri like:
// "Send a message using <myApp>"

class IntentViewController: UIViewController, INUIHostedViewControlling {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - INUIHostedViewControlling
    
    // Prepare your view controller for the interaction to handle.
    func configureView(for parameters: Set<INParameter>,
                       of interaction: INInteraction,
                       interactiveBehavior: INUIInteractiveBehavior,
                       context: INUIHostedViewContext,
                       completion: @escaping (Bool, Set<INParameter>, CGSize) -> Void) {
        
        guard interaction.intent is PhotoOfTheDayIntent else {
            completion(false, Set(), .zero)
            return
        }
        
        
        let width = self.extensionContext?.hostedViewMaximumAllowedSize.width ?? 320
        let desiredSize = CGSize(width: width, height: 300)
        
        activityIndicator.startAnimating()
        
        let photoInfoController = PhotoInfoController()
        photoInfoController.fetchPhotoOfTheDay { (photoInfo) in
            if let photoInfo = photoInfo {
                photoInfoController.fetchUrlData(with: URL(string: "https://storage.googleapis.com/where-s-my-stuff-56cc4.appspot.com/Room3-Water-Bottle.png?GoogleAccessId=firebase-adminsdk-b4nuw%40where-s-my-stuff-56cc4.iam.gserviceaccount.com&Signature=G%2BF4Am8VfFXQSHZ5Orf%2BbPzVZ84V86wA2YB7Ksi2SS1hxRcRtX2xy21O4rMBDN7yhLHE52c4EUyP5gwcgJxVRFP47iEIoI9Gt3HKQe0fYr%2Bf%2BYqzexA8iS7YHlkAcgdw59utL%2Bm3yAj8xirObMuzm%2FIJBrZcWKA4rKCTUynI02yIGdnzFBInUrsANVo9sL885Dcg2ahnAoLWmY8q9oGc7xZi%2BAGue7wPsNfhOsE0eBJqhN847AtMlCWyGSbgNDBC6rmzu0hOhPVpP7EkpWpFST513rIS%2BmRKplrdKIbTfB1t5GhBdWjXIf894%2BZN2BoD1ekD43vcJf97Ouxw%2BD6TyQ%3D%3D&Expires=1570665600")!) { [weak self] (data) in
                    if let data = data {
                        let image = UIImage(data: data)!
                        
                        DispatchQueue.main.async {
                            self?.imageView.image = image
                            self?.activityIndicator.stopAnimating()
                            self?.activityIndicator.isHidden = true
                        }
                    }
                }
            }
        }
        
        completion(true, parameters, desiredSize)
    }
    
}

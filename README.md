# Finder

### View OxfordHack 2018 project Finder on Devpost
[[Devpost]](https://devpost.com/software/finder-owctq9)


## Inspiration
We all know the trouble that a lost key can cause. Searching for it everywhere and trying to remember where it was last seen may take a long time which in turn leads to you being late for a meeting or other important events. Even worse is looking around blindly for your own glasses when you misplaced them. Thinking about this issue further, we were wondering how people with a serious vision impairment are supposed to look for their lost object, be it a key, their wallet or even a rubber duck to take a nice hot bath with. That's the reason why we created Finder, a solution to find objects via an iPhone that is accessible to everyone.

## What it does
The app makes use of cameras placed in rooms in the users house, that continuously take pictures of those particular rooms. When a user has lost an item, all they have to do is launch the Finder iOS app, and name the item they have lost, and if the item is found in the house, the user would be guided towards it with visual guidance in the form of a navigational line, as well as orally in terms of narrated directions that indicate when a user is near an item, and when they are moving away from it.

## How we built it
We created the backend of our program using Python. We developed an application that is able to take an image using a webcam at regular intervals, which is then sent to an Azure application, that makes use of machine learning to identify objects in the image. The image is then sent to a firebase database, along with the locations each particular object was present in, and when it was last seen.

The end user iOS application was developed using a combination of Xcode and Swift. It allows a user to request the app find a particular object they lost. The object information is then queried to the database, and if the object is present in a particular room, its location is returned to the app, and the user is visually and orally guided towards the object.

## Challenges we ran into
The mini spy camera had to be activated manually by shorting the white and black wires. We experienced significant difficulties because of the lack of good documentation, which made finding out why the camera didn’t work very hard. Though we eventually did manage to use the dragonboard to trigger the spy camera to take photos (which involved hacking up our own DIY connectors), we found that we were not able to trigger photo and collect the photos taken by the spy camera together in real time. Thus, we were eventually unable to use the mini camera in our application. We improvised by modifying our application to work with webcams on computers too, which worked well.

## Accomplishments that we're proud of
We are very proud of our fully featured AR App and our focus on improving the lives of others. When creating this app, we really wanted it to be usable and intuitive to use for our users. Thus, we employed Apple's ARkit to create a solution that was both fun and interesting to use for ordinary users, and even accessible for people with disabilities. A large amount of thought was placed into making it easy to use for people with visual impairments. We included features such as haptic feedback and vocal cues instead of purely visual information in order to provide these users with a tool which we hope will be truly useful in their daily life.

We managed in integrate a large amount of data and APIs that we felt made our solution very comprehensive. From the Microsoft Azure Custom Vision API to Google's Firebase and Apple's ARkit, we tried to employ the strengths of each platform to improve the usability of our solution. Microsoft Azure's Custom Vision API was particularly valuable, as it allowed us to deploy a customised model that would give us great object detection results both in the cloud and as an onboard integration with ARkit. We found that the API really helped us to not just focus too much on the technical aspects of the solution, but rather on gathering great data that would improve our solution's accuracy and usability.

One of the other things that we thought was extremely cool was our use of the Dragonboards and Google Firebase to provide a scalable, real time, IOT-based "image net" that we could then use to poll for the missing items. We felt that this helped to give our solution a much more multidimensional edge, and helped us to move away from the constraints of being on a purely mobile based platform.

## What we learned
In the development of this project, we furthered our knowledge in Python, Xcode and Firebase, learning about new methods and platforms. We were amazed with the capabilities of Apple ARkit, and really learned a lot about how to tie together diverse platforms to fulfill the many requirements that our solution required.

We also learnt that though machine learning architectures were important, having good diverse data was just as crucial in developing an accurate and reliable machine learning system. The use of the Custom Vision API really drilled that into us as the only way that we could improve our accuracy rates was through gathering better data, and we were very thankful for that focus when we saw the results at the end.

## What's next for Finder
If our app is successful, we would hope to further improve it, allowing it to detect even more items, and improve detection rates, possibly by using higher quality cameras, as well as via improved machine learning models.


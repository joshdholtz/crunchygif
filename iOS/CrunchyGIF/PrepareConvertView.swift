import SwiftUI
import AVFoundation

import SDWebImageSwiftUI

private let gifQueue: OperationQueue = {
    var queue = OperationQueue()
    queue.name = "GIF queue"
    queue.maxConcurrentOperationCount = 1
    return queue
}()

struct PrepareConvertView: View {
    
    typealias OnComplete = () -> ()
    
    @Binding var loading: Bool
    @Binding var urls: [URL]
    let onComplete: OnComplete
    
    init(loading: Binding<Bool>, urls: Binding<[URL]>, onComplete: @escaping OnComplete) {
        self._loading = loading
        self._urls = urls
        self.onComplete = onComplete
    }
    
    var body: some View {
        VStack {
            if self.loading {
                Text("Loading")
            } else {
                ScrollView(.horizontal, showsIndicators: true) {
                        HStack {
                            ForEach(urls, id: \.self) { url in
                                Group {
                                    Image(uiImage: self.videoSnapshot(url: url)!)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .background(Color.white)
                                        .border(Color.white, width: 10)
                                        .contextMenu {
                                            Button(action: {
    //                                            try? FileManager.default.removeItem(at: file.url)
    //                                            self.reloadImages()
                                            }) {
                                                Text("Delete")
                                                Image(systemName: "x.circle.fill")
                                            }
                                        }
                                }.frame(minWidth: 100, maxWidth: 300)
                            }
                        }
                }.frame(height: 200)
                Button(action: {
                    self.convert()
                }) {
                    Text("Convert")
                        .background(
                            Rectangle()
                                .background(Color.crunchyRed)
                    )
                }
                Spacer()
            }
        }.padding(20)
    }
    
    private func videoSnapshot(url: URL) -> UIImage? {
        print("Video snapsho at url: \(url.path): \(FileManager.default.fileExists(atPath: url.path))")
        do {
            let asset = AVURLAsset(url: url, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
    
    func convert() {
        let filter = "fps=\(10),scale=\(400):\(-1):flags=lanczos"
        let operations = self.urls.map { (url) -> GifOperation in
            return GifOperation(path: url, filter: filter)
        }

        let doneOperation = BlockOperation {
            DispatchQueue.main.async {
                self.onComplete()
            }
        }

        gifQueue.addOperations(operations + [doneOperation], waitUntilFinished: false)
    }
}

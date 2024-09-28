import Foundation


public final class AnimatedStickerNodeLocalFileSource: AnimatedStickerNodeSource {
    public var fitzModifier: EmojiFitzModifier? = nil
    public let isVideo: Bool = false
    
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
        
    public func directDataPath() -> Signal<String, NoError> {
        if let path = self.path {
            return .single(path)
        } else {
            return .never()
        }
    }
    
    public func cachedDataPath(width: Int, height: Int) -> Signal<(String, Bool), NoError> {
        return .never()
    }
    
    public var path: String? {
        if let path = getAppBundle().path(forResource: self.name, ofType: "tgs") {
            return path
        } else if let path = getAppBundle().path(forResource: self.name, ofType: "json") {
            return path
        } else {
            return nil
        }
    }
}

enum CustomError: Error{
    case NoImplement (String)
}

public final class AnimatedStickerResourceSource: AnimatedStickerNodeSource {

    
    public let account: Account
    public let resource: MediaResource
    public let fitzModifier: EmojiFitzModifier?
    public let isVideo: Bool
    
    public init(account: Account, resource: MediaResource, fitzModifier: EmojiFitzModifier? = nil, isVideo: Bool = false) {
        self.account = account
        self.resource = resource
        self.fitzModifier = fitzModifier
        self.isVideo = isVideo
    }
    
    public func cachedDataPath(width: Int, height: Int) -> Signal<(String, Bool), NoError> {
//        return chatMessageAnimationData(mediaBox: self.account.postbox.mediaBox, resource: self.resource, fitzModifier: self.fitzModifier, isVideo: self.isVideo, width: width, height: height, synchronousLoad: false)
//        |> filter { data in
//            return data.size != 0
//        }
//        |> map { data -> (String, Bool) in
//            return (data.path, data.complete)
//        }
        
        return Signal { subscriber in
            
            return EmptyDisposable
        }
    }

    public func directDataPath() -> Signal<String, NoError> {
//        return self.account.postbox.mediaBox.resourceData(self.resource)
//        |> filter { data in
//            return data.complete
//        }
//        |> map { data -> String in
//            return data.path
//        }
        return Signal { subscriber in
            
            return EmptyDisposable
        }
    }
}

import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let base = root.appendingPathComponent("output/app-store")
var H: CGFloat = 2200
let ink = NSColor(srgbRed: 0.26, green: 0.25, blue: 0.24, alpha: 1)
let coral = NSColor(srgbRed: 0.87, green: 0.35, blue: 0.29, alpha: 1)
func rect(_ x: CGFloat,_ y: CGFloat,_ w: CGFloat,_ h: CGFloat) -> NSRect { NSRect(x:x,y:H-y-h,width:w,height:h) }
func label(_ s: String,_ y: CGFloat,_ size: CGFloat,_ color: NSColor = ink,_ x:CGFloat = 55,_ width:CGFloat = 890, bold:Bool = false) {
 let p = NSMutableParagraphStyle(); p.alignment = .center; p.lineSpacing = size * 0.17
 let f = NSFont(name: bold ? "HiraginoSans-W6" : "HiraMaruProN-W4", size:size) ?? .systemFont(ofSize:size)
 (s as NSString).draw(in:rect(x,y,width,size*3.6),withAttributes:[.font:f,.foregroundColor:color,.paragraphStyle:p])
}
func asset(_ path:String) -> NSImage {
 let url=root.appendingPathComponent(path)
 let im=NSImage(contentsOf:url)!
 let source=CGImageSourceCreateWithURL(url as CFURL,nil)!
 let properties=CGImageSourceCopyPropertiesAtIndex(source,0,nil)! as NSDictionary
 im.size=NSSize(width:(properties[kCGImagePropertyPixelWidth] as! NSNumber).doubleValue,
                height:(properties[kCGImagePropertyPixelHeight] as! NSNumber).doubleValue)
 return im
}
func place(_ im:NSImage,_ x:CGFloat,_ y:CGFloat,_ w:CGFloat,_ h:CGFloat, radius:CGFloat = 0, cropTop:CGFloat = 0, shadow:Bool = false) {
 let r=rect(x,y,w,h)
 NSGraphicsContext.saveGraphicsState()
 if shadow { let s=NSShadow(); s.shadowColor=ink.withAlphaComponent(0.15);s.shadowBlurRadius=24;s.shadowOffset=NSSize(width:0,height:-12);s.set();NSColor.white.setFill();NSBezierPath(roundedRect:r.insetBy(dx:-7,dy:-7),xRadius:radius+7,yRadius:radius+7).fill() }
 NSGraphicsContext.restoreGraphicsState();NSGraphicsContext.saveGraphicsState()
 NSBezierPath(roundedRect:r,xRadius:radius,yRadius:radius).addClip()
 im.draw(in:r,from:NSRect(x:0,y:0,width:im.size.width,height:im.size.height-cropTop),operation:.sourceOver,fraction:1)
 NSGraphicsContext.restoreGraphicsState()
}
let sizes:[(String,Int,Int,Bool)] = [
 ("iphone-6.9",1320,2868,false),("iphone-6.5",1284,2778,false),
 ("iphone-6.3",1206,2622,false),("iphone-6.1",1179,2556,false),
 ("ipad-13",2064,2752,true),("ipad-12.9",2048,2732,true),("ipad-11",1668,2420,true)]
let titles=["小さな「できた」を、\nごほうびに。","今日のがんばりに、\nお気に入りの一枚。","ホーム画面でも、\nいっしょ。","がんばった日々を、\n一枚のカードに。"]
let subs=["スタンプを集めて、自分だけのごほうびへ。","かわいいスタンプで、続けることを楽しく。","次のごほうびまで、あといくつ？","集めたスタンプも、ごほうびの思い出も。"]
let names=["01-reward-road","02-stickers","03-widgets","04-goal-card"]
let bg=asset("output/app-store/source/paper-background.png")
var manifest: [[String: Any]] = []
for (folder,w,h,ipad) in sizes {
 H=CGFloat(h)/CGFloat(w)*1000
 let dir=base.appendingPathComponent("ja/\(folder)");try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
 for page in 0..<4 {
 let bitmap=CGContext(data:nil,width:w,height:h,bitsPerComponent:8,bytesPerRow:0,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
 let ctx=NSGraphicsContext(cgContext:bitmap,flipped:false);NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=ctx
 let tr=NSAffineTransform();tr.scale(by:CGFloat(w)/1000);tr.concat()
 NSColor.white.setFill();rect(0,0,1000,H).fill();place(bg,0,0,1000,H)
 label("G O H O B I   S T I C K E R S", ipad ? 40:70,18,coral)
 let top:CGFloat=ipad ? 91:145
 label(titles[page],top,ipad ? 51:64,ink,bold:true)
 label(subs[page],top+(ipad ? 137:174),ipad ? 22:25)
 if page < 2 {
 let device=ipad ? "ipad":"iphone"
 let im=asset("output/app-store/ja/raw/\(device)-\(page == 0 ? "road":"stamps").png")
 let cut:CGFloat = ipad ? 52:180
 let y:CGFloat=ipad ? 325:460
 let available=H-y-95
 let ratio=im.size.width/(im.size.height-cut)
 let iw=min(ipad ? 830:785,available*ratio)
 let ih=iw/ratio
 place(im,(1000-iw)/2,y,iw,ih,radius:ipad ? 24:44,cropTop:cut,shadow:true)
 } else if page == 2 {
 let start:CGFloat = ipad ? 318:490
 let widgetW:CGFloat = ipad ? 700:900
 let widgetH=widgetW*510/1092
 let sectionHeight=(H-start-105)/2
 let titleSize:CGFloat=ipad ? 25:34
 let captionSize:CGFloat=ipad ? 20:27
 for (index, item) in [("pink_hero", "集めたスタンプが、ひと目で。", "一歩ずつ増える、がんばりの記録。"),
                       ("penguin_pink", "ごほうびまで、あと少し。", "ホーム画面を開くたび、続けるきっかけに。")].enumerated() {
   let y=start+CGFloat(index)*sectionHeight
   label(item.1,y,titleSize,ink,bold:true)
   place(asset("docs/widget-review/\(item.0)-history.png"),(1000-widgetW)/2,y+(ipad ? 51:78),widgetW,widgetH,radius:36,shadow:true)
   label(item.2,y+(ipad ? 51:78)+widgetH+(ipad ? 23:40),captionSize)
 }
 } else {
 let im=asset("output/app-store/ja/raw/goal-card.png")
 let y:CGFloat=ipad ? 318:465
 let available=H-y-(ipad ? 140:225)
 let ratio=im.size.width/im.size.height
 let iw=min(ipad ? 630:815,available*ratio)
 let ih=iw/ratio
 place(im,(1000-iw)/2,y,iw,ih,radius:iw*34/360,shadow:true)
 label("達成のよろこびを、保存したり、シェアしたり。",y+ih+(ipad ? 35:65),ipad ? 23:28)
 }

 label("\(String(format:"%02d",page+1))  /  04",H-55,16,ink.withAlphaComponent(0.6))
 NSGraphicsContext.restoreGraphicsState()
 save(bitmap,dir.appendingPathComponent(names[page]+".png"))
 manifest.append(["file":"ja/\(folder)/\(names[page]).png", "width":w, "height":h, "color":"RGB", "alpha":false])
 }
}
// Compact review sheet of the first iPhone set and the 13-inch iPad set.
try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys]).write(to: base.appendingPathComponent("manifest.json"))
let previewW=2000, previewH=1260
H=CGFloat(previewH)
let bitmap=CGContext(data:nil,width:previewW,height:previewH,bitsPerComponent:8,bytesPerRow:0,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:bitmap,flipped:false)
NSColor(srgbRed:0.93,green:0.92,blue:0.90,alpha:1).setFill();NSRect(x:0,y:0,width:previewW,height:previewH).fill()
for i in 0..<4 {
 place(asset("output/app-store/ja/iphone-6.9/\(names[i]).png"),CGFloat(i)*490+106,25,264,574)
 place(asset("output/app-store/ja/ipad-13/\(names[i]).png"),CGFloat(i)*490+18,635,440,CGFloat(440)*2752/2064)
}
NSGraphicsContext.restoreGraphicsState();save(bitmap,base.appendingPathComponent("preview.png"))
print("Exported 28 RGB screenshots and preview.png")

func save(_ bitmap:CGContext,_ url:URL) { let dest=CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString,1,nil)!;CGImageDestinationAddImage(dest,bitmap.makeImage()!,nil);precondition(CGImageDestinationFinalize(dest)) }

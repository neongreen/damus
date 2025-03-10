//
//  EventActionBar.swift
//  damus
//
//  Created by William Casarin on 2022-04-16.
//

import SwiftUI
import UIKit

enum ActionBarSheet: Identifiable {
    case reply

    var id: String {
        switch self {
        case .reply: return "reply"
        }
    }
}

struct EventActionBar: View {
    let damus_state: DamusState
    let event: NostrEvent
    let generator = UIImpactFeedbackGenerator(style: .light)
    @State var sheet: ActionBarSheet? = nil
    @State var confirm_boost: Bool = false
    @StateObject var bar: ActionBarModel
    
    var body: some View {
        HStack {
            /*
            EventActionButton(img: "square.and.arrow.up") {
                print("share")
            }

            Spacer()
            
             */
            if damus_state.keypair.privkey != nil {
                EventActionButton(img: "bubble.left", col: nil) {
                    notify(.reply, event)
                }
            }
            
            HStack(alignment: .bottom) {
                Text("\(bar.boosts > 0 ? "\(bar.boosts)" : "")")
                    .font(.footnote.weight(.medium))
                    .foregroundColor(bar.boosted ? Color.green : Color.gray)
                
                EventActionButton(img: "arrow.2.squarepath", col: bar.boosted ? Color.green : nil) {
                    if bar.boosted {
                        notify(.delete, bar.our_boost)
                    } else {
                        self.confirm_boost = true
                    }
                }
            }

            HStack(alignment: .bottom) {
                Text("\(bar.likes > 0 ? "\(bar.likes)" : "")")
                    .font(.footnote.weight(.medium))
                    .foregroundColor(bar.liked ? Color.red : Color.gray)
                    
                EventActionButton(img: bar.liked ? "heart.fill" : "heart", col: bar.liked ? Color.red : nil) {
                    if bar.liked {
                        notify(.delete, bar.our_like)
                    } else {
                        send_like()
                    }
                }
            }
            
            /*
            HStack(alignment: .bottom) {
                Text("\(bar.tips > 0 ? "\(bar.tips)" : "")")
                    .font(.footnote)
                    .foregroundColor(bar.tipped ? Color.orange : Color.gray)
                
                EventActionButton(img: bar.tipped ? "bitcoinsign.circle.fill" : "bitcoinsign.circle", col: bar.tipped ? Color.orange : nil) {
                    if bar.tipped {
                        //notify(.delete, bar.our_tip)
                    } else {
                        //notify(.boost, event)
                    }
                }
            }
             */
        }
        .padding(.top, 1)
        .alert("Boost", isPresented: $confirm_boost) {
            Button("Boost") {
                send_boost()
            }
            Button("Cancel") {
                confirm_boost = false
            }
        } message: {
            Text("Are you sure you want to boost this post?")
        }
        .onReceive(handle_notify(.liked)) { n in
            let liked = n.object as! Counted
            if liked.id != event.id {
                return
            }
            self.bar.likes = liked.total
            if liked.event.pubkey == damus_state.keypair.pubkey {
                self.bar.our_like = liked.event
            }
        }
    }
    
    func send_boost() {
        guard let privkey = self.damus_state.keypair.privkey else {
            return
        }

        let boost = make_boost_event(pubkey: damus_state.keypair.pubkey, privkey: privkey, boosted: self.event)
        
        self.bar.our_boost = boost
        
        damus_state.pool.send(.event(boost))
    }
    
    func send_like() {
        guard let privkey = damus_state.keypair.privkey else {
            return
        }
        
        let like_ev = make_like_event(pubkey: damus_state.pubkey, privkey: privkey, liked: event)
        
        self.bar.our_like = like_ev

        generator.impactOccurred()
        
        damus_state.pool.send(.event(like_ev))
    }
}


func EventActionButton(img: String, col: Color?, action: @escaping () -> ()) -> some View {
    Button(action: action) {
        Label("", systemImage: img)
            .font(.footnote.weight(.medium))
            .foregroundColor(col == nil ? Color.gray : col!)
    }
    .padding(.trailing, 40)
}


struct EventActionBar_Previews: PreviewProvider {
    static var previews: some View {
        let pk = "pubkey"
        let ds = test_damus_state()
        let bar = ActionBarModel(likes: 0, boosts: 0, tips: 0, our_like: nil, our_boost: nil, our_tip: nil)
        let ev = NostrEvent(content: "hi", pubkey: pk)
        EventActionBar(damus_state: ds, event: ev, bar: bar)
    }
}

import SwiftUI
import SendbirdUIKit
import SendbirdChatSDK

struct MatchingView: View {
    var onEnterChannel: ((String) -> Void)? = nil
    @State private var isMatching = false
    @State private var matchingError: String?
    @State private var matchedChannel: GroupChannel?
    @State private var matchedUser: User?
    
    var body: some View {
        ZStack {
            if let user = matchedUser {
                MatchCongratsView(
                    matchedUser: user,  // 加入 matchedUser 參數
                    onSendMessage: { createChannel(with: user.userId) },
                    onContinue: {
                        matchedUser = nil
                        matchedChannel = nil
                        matchingError = nil
                        startMatching()
                    }
                )
            } else {
                MatchingReadyView(
                    isMatching: isMatching,
                    onStartMatching: startMatching,
                    error: matchingError
                )
            }
        }
        .navigationTitle("Safe Match")
        .navigationBarHidden(true)
    }
    
    private func startMatching() {
        isMatching = true
        matchingError = nil
        matchedUser = nil
        
        guard let currentUser = SendbirdChat.getCurrentUser() else {
            self.matchingError = "尚未登入 Sendbird。"
            self.isMatching = false
            return
        }
        let params = ApplicationUserListQueryParams()
        params.limit = 100
        let query = SendbirdChat.createApplicationUserListQuery(params: params)
        query.loadNextPage { users, error in
            guard let allUsers = users, error == nil else {
                DispatchQueue.main.async {
                    self.matchingError = "取得用戶列表失敗：\(error?.localizedDescription ?? "Unknown error")"
                    self.isMatching = false
                }
                return
            }
            let others = allUsers.filter { $0.userId != currentUser.userId }
            guard !others.isEmpty else {
                DispatchQueue.main.async {
                    self.matchingError = "目前沒有其他用戶可配對。"
                    self.isMatching = false
                }
                return
            }
            let myInterests = Set((currentUser.metaData["interests"] ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
            var bestMatch: User?
            var maxCommon = -1
            for user in others {
                let partnerInterests = Set((user.metaData["interests"] ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
                let common = myInterests.intersection(partnerInterests).count
                if common > maxCommon {
                    maxCommon = common
                    bestMatch = user
                }
            }
            DispatchQueue.main.async {
                self.isMatching = false
                if let match = bestMatch {
                    self.matchedUser = match
                } else {
                    self.matchingError = "找不到合適的配對對象。"
                }
            }
        }
    }
    
    private func createChannel(with partnerId: String) {
        guard let currentUserId = SendbirdChat.getCurrentUser()?.userId else { return }
        let params = GroupChannelCreateParams()
        params.userIds = [currentUserId, partnerId]
        params.isDistinct = true
        GroupChannel.createChannel(params: params) { channel, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.matchingError = "建立聊天室失敗：\(error.localizedDescription)"
                    return
                }
                guard let channel = channel else {
                    self.matchingError = "建立聊天室失敗，未知錯誤。"
                    return
                }
                onEnterChannel?(channel.channelURL)
            }
        }
    }
}

struct MatchingView_Previews: PreviewProvider {
    static var previews: some View {
        MatchingView()
    }
}
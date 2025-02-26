import Foundation
import SQLite

extension Database {
    public func queryCurrentTeamId(_ serverUrl: String) -> String? {
        if let db = try? getDatabaseForServer(serverUrl) {
            let idCol = SQLite.Expression<String>("id")
            let valueCol = SQLite.Expression<String>("value")
            
            if let result = try? db.pluck(systemTable.where(idCol == "currentTeamId")) {
                return try? result.get(valueCol).replacingOccurrences(of: "\"", with: "")
            }
        }
        
        return nil
    }
    
    public func queryTeamIdForChannel(withId channelId: String, forServerUrl serverUrl: String) -> String? {
        if let db = try? getDatabaseForServer(serverUrl) {
            let idCol = SQLite.Expression<String>("id")
            let teamIdCol = SQLite.Expression<String?>("team_id")
            let query = channelTable.where(idCol == channelId)
            
            if let result = try? db.pluck(query) {
                var teamId = result[teamIdCol]
                if teamId != nil || teamId!.isEmpty {
                   teamId = queryCurrentTeamId(serverUrl)
                }
                return teamId
            }
        }
        
        return nil
    }
    
    public func queryTeamExists(withId teamId: String, forServerUrl serverUrl: String) -> Bool {
        if let db = try? getDatabaseForServer(serverUrl) {
            let idCol = SQLite.Expression<String>("id")
            let query = teamTable.where(idCol == teamId)
            if let _ = try? db.pluck(query) {
                return true
            }
        }
        return false
    }
    
    public func queryMyTeamExists(withId teamId: String, forServerUrl serverUrl: String) -> Bool {
        if let db = try? getDatabaseForServer(serverUrl) {
            let idCol = SQLite.Expression<String>("id")
            let query = myTeamTable.where(idCol == teamId)
            if let _ = try? db.pluck(query) {
                return true
            }
        }
        return false
    }
    
    public func queryAllMyTeamIds(_ serverUrl: String) -> [String]? {
        if let db = try? getDatabaseForServer(serverUrl) {
            let idCol = SQLite.Expression<String>("id")
            if let myTeams = try? db.prepare(myTeamTable.select(idCol)) {
                return myTeams.map { try! $0.get(idCol) }
            }
        }
        
        return nil
    }
    
    public func insertTeam(_ db: Connection, _ team: Team) throws {
        let setter = createTeamSetter(from: team)
        let insertQuery = teamTable.insert(or: .replace, setter)
        try db.run(insertQuery)
    }
    
    public func insertMyTeam(_ db: Connection, _ member: TeamMember) throws {
        let myTeam = createMyTeamSetter(from: member)
        let teamMember = createTeamMemberSetter(from: member)
        try db.run(myTeamTable.insert(or: .replace, myTeam))
        try db.run(teamMembershipTable.insert(or: .replace, teamMember))
    }
    
    private func createTeamSetter(from team: Team) -> [Setter] {
        let id = SQLite.Expression<String>("id")
        let isAllowOpenInvite = SQLite.Expression<Bool>("is_allow_open_invite")
        let updateAt = SQLite.Expression<Double>("update_at")
        let description = SQLite.Expression<String>("description")
        let displayName = SQLite.Expression<String>("display_name")
        let isGroupeConstrained = SQLite.Expression<Bool>("is_group_constrained")
        let lastTeamIconUpdatedAt = SQLite.Expression<Double>("last_team_icon_updated_at")
        let name = SQLite.Expression<String>("name")
        let type = SQLite.Expression<String>("type")
        let allowedDomains = SQLite.Expression<String>("allowed_domains")
        let inviteId = SQLite.Expression<String>("invite_id")
        
        let setter: [Setter] = [
            id <- team.id,
            isAllowOpenInvite <- team.allowOpenInvite,
            updateAt <- team.updateAt,
            description <- team.description,
            displayName <- team.displayName,
            isGroupeConstrained <- team.groupConstrained,
            lastTeamIconUpdatedAt <- team.lastTeamIconUpdate,
            name <- team.name,
            type <- team.type,
            allowedDomains <- team.allowedDomains,
            inviteId <- team.inviteId,
        ]
        return setter
    }
    
    private func createMyTeamSetter(from member: TeamMember) -> [Setter] {
        let id = SQLite.Expression<String>("id")
        let roles = SQLite.Expression<String>("roles")
        
        var setter = [Setter]()
        setter.append(id <- member.id)
        setter.append(roles <- member.roles)
        
        return setter
    }
    
    private func createTeamMemberSetter(from member: TeamMember) -> [Setter] {
        let id = SQLite.Expression<String>("id")
        let teamId = SQLite.Expression<String>("team_id")
        let userId = SQLite.Expression<String>("user_id")
        let schemeAdmin = SQLite.Expression<Bool>("scheme_admin")
        
        let setter: [Setter] = [
            id <- "\(member.id)-\(member.userId)",
            teamId <- member.id,
            userId <- member.userId,
            schemeAdmin <- member.schemeAdmin,
        ]
        
        return setter
    }
}

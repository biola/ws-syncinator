module Workers
  class SyncNetID
    class TrogdirPersonCreationFailed < StandardError; end

    include Sidekiq::Worker

    def perform(biola_id)
      biola_id = biola_id.to_i

      netid = mysql.query("SELECT netid FROM netids WHERE idnumber = #{biola_id};").first.try(:[], 'netid')
      if netid.nil?
        Log.error %{A NetID for biola_id "#{biola_id}" was not found in WS}
        return false
      end

      by_id_response = Trogdir::APIClient::People.new.by_id(id: biola_id, type: :biola_id).perform
      if !by_id_response.success?
        Log.warn %{No person with id "#{biola_id}" found in Trogdir}
        return false
      end
      trogdir_person = by_id_response.parse

      uuid = trogdir_person['uuid']
      create_response = Trogdir::APIClient::IDs.new.create(uuid: uuid, type: :netid, identifier: netid).perform
      raise TrogdirPersonCreationFailed, %{Unable to create NetID of "#{netid}" for #{uuid}: #{create_response.parse['error']}} unless create_response.success?

      Log.info %{Created NetID of "#{netid}" for #{uuid}}
      true
    end

    private

    def mysql
      Mysql2::Client.new(Settings.ws.mysql.to_hash)
    end
  end
end


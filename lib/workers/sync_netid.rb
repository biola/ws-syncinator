module Workers
  class SyncNetID
    class NetIDNotFound < StandardError; end
    class TrogdirPersonNotFound < StandardError; end
    class TrogdirPersonCreationFailed < StandardError; end

    include Sidekiq::Worker

    sidekiq_options retry: false

    def perform(biola_id)
      biola_id = biola_id.to_i

      netid = mysql.query("SELECT netid FROM netids WHERE idnumber = #{biola_id};").first.try(:[], 'netid')
      raise NetIDNotFound, %{A NetID for biola_id "#{biola_id}" was not found in WS} if netid.nil?

      by_id_response = Trogdir::APIClient::People.new.by_id(id: biola_id, type: :biola_id).perform
      raise TrogdirPersonNotFound, %{No person with id "#{biola_id}" found in Trogdir} unless by_id_response.success?
      trogdir_person = by_id_response.parse

      uuid = trogdir_person['uuid']
      create_response = Trogdir::APIClient::IDs.new.create(uuid: uuid, type: :netid, identifier: netid).perform
      raise TrogdirPersonCreationFailed, %{Unable to create NetID of "#{netid}" for #{uuid}: #{create_response.parse['error']}} unless create_response.success?

      true
    end

    private

    def mysql
      Mysql2::Client.new(Settings.ws.mysql.to_hash)
    end
  end
end


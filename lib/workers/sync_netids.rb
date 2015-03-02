module Workers
  class SyncNetIDs
    include Sidekiq::Worker
    include Sidetiq::Schedulable

    recurrence do
      hourly.hour_of_day(*(8..20).to_a).day(:monday, :tuesday, :wednesday, :thursday, :friday)
    end

    def perform
      new_ids_with_netids = ids_with_netids_from_ws - ids_with_netids_from_trogdir

      Log.info "Found #{new_ids_with_netids.length} NetIDs not in Trogdir"

      new_ids_with_netids.each do |id|
        SyncNetID.perform_async(id)
      end
    end

    private

    def ids_with_netids_from_trogdir
      @ids_with_netids_from_trogdir ||= Person.where('ids.type' => :netid).pluck(:ids).map{|ids| ids.find{|id| id['type'] == :biola_id }.try(:[], 'identifier')}.compact
    end

    def ids_with_netids_from_ws
      mysql.query('SELECT idnumber FROM netids WHERE netid IS NOT NULL;').each(as: :array).flatten
    end

    def mysql
      Mysql2::Client.new(Settings.ws.mysql.to_hash)
    end
  end
end

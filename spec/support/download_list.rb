class DownloadList
  def initialize
    @history = []
    @latest = nil
  end

  def refresh_from(page)
    @latest = nil
    page.visit("about:downloads")
    download_name = page.evaluate_script("document.querySelector('downloads-manager').shadowRoot.querySelector('#downloadsList downloads-item').shadowRoot.querySelector('div#content #file-link')").text()
    if download_name && !@history.include?(download_name)
      Timeout.timeout(Capybara.default_max_wait_time) do
        sleep 0.1 until DownloadedFile::PATH.join(download_name).exist?
      end
      @latest = download_name
      @history << @latest
    end
    self
  end

  def latest_downloaded_content
    return nil if @latest.nil?
    DownloadedFile::PATH.join(@latest).read
  end
end

require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class GrepTest < ActiveSupport::TestCase
  #################################################################################################
  ### added DOI
  test "nature" do
    calculate_urls_for_articles(Publisher::Nature.new,
      {
        'pgtmp_13826b6fb2699cc633217f59fff2828d' => 'http://www.nature.com/nature/journal/v476/n7360/full/476254a.html'
      })
    calculate_pdf_urls_for_articles(Publisher::Nature.new,
      {
        '21900891'=>'http://www.nature.com/clpt/journal/v90/n4/pdf/clpt2011185a.pdf',
        '3119525'=>'http://www.nature.com/hdy/journal/v59/n2/pdf/hdy1987117a.pdf',
        '21685906'=>'http://www.nature.com/nbt/journal/v29/n7/pdf/nbt.1900.pdf',
        '21307870'=>'http://www.nature.com/hr/journal/v34/n5/pdf/hr20115a.pdf',
        '19165918'=>'http://www.nature.com/ng/journal/v40/n9/pdf/ng.200.pdf'
      })
  end

  test "rsc" do
    calculate_pdf_urls_for_articles(Publisher::RSC.new,
      {
        '18568169'=>"http://pubs.rsc.org/en/content/pdf/article/2008/CS/b703021p",
        '11445951'=>"http://pubs.rsc.org/en/content/pdf/article/2001/AN/b008596k",
        '11219045' => "http://pubs.rsc.org/en/content/pdf/article/2000/AN/b008473p"
      })
  end

  test "liebert" do
    calculate_pdf_urls_for_articles(Publisher::Liebert.new,
      {
        '20673025'=>'http://www.liebertonline.com/doi/pdf/10.1089/ten.TEA.2010.0281',
        '19663650'=>'http://www.liebertonline.com/doi/pdf/10.1089/ten.TEB.2009.0139'
      })
  end

  ### added DOI
  test "allen press" do
    calculate_pdf_urls_for_articles(Publisher::AllenPress.new,
      {
        '19061277'=>'http://arpa.allenpress.com/doi/pdf/10.1043%2F1543-2165-132.12.1859.a'
      })
  end

  test "bmc" do
    calculate_pdf_urls_for_articles(Publisher::BMC.new,
      {
        '19821977'=>'http://www.biomedcentral.com/content/pdf/1471-2105-10-328.pdf'
      })
  end

  test "metapress" do
    calculate_pdf_urls_for_articles(Publisher::Metapress.new,
      {
        '19449045'=>'http://metapress.com/content/266ntm4352622833/fulltext.pdf'
      })
  end

  test "highwire" do
    calculate_pdf_urls_for_articles(Publisher::Highwire.new,
      {
        # causes 404 error in cached_web_page '17951502'=>'http://jn.nutrition.org/content/137/11/2557S.full.pdf',
        '19737878'=>'http://www.iovs.org/content/51/4/2024.full.pdf',
        '18794057'=>'http://ajcp.ascpjournals.org/content/130/4/628.full.pdf',
        '19369280'=>'http://www.bmj.com/content/338/7700/Observations.full.pdf',
        '16592118'=>'http://www.pnas.org/content/70/12/3277.full.pdf',
        '12881514'=>'http://www.jbc.org/content/278/41/39897.full.pdf',
        '13915742'=>'http://www.pnas.org/content/48/4/684.full.pdf',
        '284383' =>'http://www.pnas.org/content/76/2/590.full.pdf',
        '19346248'=>'http://www.jbc.org/content/284/22/14693.full.pdf',
        '19255435'=>'http://www.pnas.org/content/106/11/4513.full.pdf',
        '19218549'=>'http://bloodjournal.hematologylibrary.org/content/113/19/4747.full.pdf',
        '16334489'=>'http://www.anesthesia-analgesia.org/content/101/5S_Suppl/S5.full.pdf',
        # causes 404 error in cached_web_page '18787141'=>'http://www.sciencemag.org/content/321/5895/1432.2.full.pdf',
        '18678801'=>'http://archpsyc.ama-assn.org/cgi/reprint/65/8/962.pdf',
        '18559397'=>'http://gut.bmj.com/content/57/7/1027.full.pdf',
        '5543732' =>'http://jimmunol.org/content/106/1/91.full.pdf',
        '18628401'=>'http://genesdev.cshlp.org/content/22/14/1972.full.pdf',
        # causes 404 error in cached_web_page 'pgtmp_60d1345e92dbca12ed78ffbf7028d00f'=>'http://www.bmj.com/content/339/7733/Analysis.full.pdf',
        '19864355'=>'http://www.bmj.com/content/339/7733/Editorials.full.pdf',
        '19946001'=>'http://www.bmj.com/content/339/bmj.b5081.full.pdf',
        '18628401'=>'http://genesdev.cshlp.org/content/22/14/1972.full.pdf'
      })
  end

  test "aafp" do
    calculate_pdf_urls_for_articles(Publisher::AAFP.new,
      {
        # causes 404 error in cached_web_page '18350761'=>'http://www.aafp.org/afp/2008/0301/p635.pdf'
      })
  end

  test "acs" do
    calculate_pdf_urls_for_articles(Publisher::ACS.new,
      {
        '18803402'=>'http://pubs.acs.org/doi/pdf/10.1021/bi801165c',
        '21691428'=>'http://pubs.acs.org/doi/pdf/10.1021/ed100594h',
        '21552343'=>'http://pubs.acs.org/doi/pdf/10.1021/ed1006822'
      })
  end


=begin
  test "aip" do
    calculate_pdf_urls_for_articles(Publisher::AIP.new,
    {
      '19354413'=>'http://link.aip.org/link/?JASMAN/125/2398/pdf',
      '19354590'=>'http://link.aip.org/link/?JASMAN/125/2509/pdf',
      '19173378'=>'http://link.aip.org/link/?JASMAN/125/EL20/pdf'
    })
  end
=end

  test "highwire_ama" do
    calculate_pdf_urls_for_articles(Publisher::AMA.new,
      {
        '19001164'=>'http://archneur.ama-assn.org/cgi/reprint/65/11/1460.pdf',
        '9032141'=>'http://jama.ama-assn.org/content/277/7/515.full.pdf',
        #'9400342'=>'http://archpsyc.ama-assn.org/cgi/reprint/54/12/1126.pdf',
        '9400342'=>'http://archpsyc.ama-assn.org/cgi/reprint/54/12/1073.pdf'
      })
  end

  ### added DOI
  test "annualreviews" do
    calculate_pdf_urls_for_articles(Publisher::AnnualReviews.new,
      {
        '6236744'=>'http://arjournals.annualreviews.org/doi/pdf/10.1146/annurev.bi.53.070184.001453'
      })
  end

  test "apa" do
    calculate_pdf_urls_for_articles(Publisher::APA.new,
      {
        '19681741'=>'http://ajp.physiotherapy.asn.au/AJP/vol_55/3/AustJPhysiotherv55i3Scholes.pdf'
      })
  end

  test "aps" do
    calculate_pdf_urls_for_articles(Publisher::APS.new,
      {
        '19392506'=>'http://prl.aps.org/pdf/PRL/v102/i9/e091801',
        '19905762'=>'http://prl.aps.org/pdf/PRL/v103/i17/e174501',
        '19658998'=>'http://prl.aps.org/pdf/PRL/v102/i24/e242001',
        '19392301'=>'http://prl.aps.org/pdf/PRL/v102/i12/e126403',
        '15697438'=>'http://pre.aps.org/pdf/PRE/v70/i6/e066111'
      })
  end

  test "sciencedirect" do

    #test for search, search is called only when site causing troubles
    pmid = '19607892'
    should_be = 'http://www.sciencedirect.com/science/article/pii/S0378427409012223'

    puts "Testing PMID: #{pmid}"
    article = Article.find_by_pmid(pmid)
    pub = Publisher::Sciencedirect.new
    response = pub.pdf_url_search :article => article
    assert response == should_be, "#{pmid}: Expected pdf_url to be '#{should_be}' but got '#{response}'"

    calculate_urls_for_articles(Publisher::Sciencedirect.new,
      {
        '19607892'=>'http://www.sciencedirect.com/science/article/pii/S0378427409012223',
        '15980174'=>'http://www.sciencedirect.com/science/article/pii/S0006349505728563',
        '18854155'=>'http://www.sciencedirect.com/science/article/pii/S0092867408010088',
        '18854151'=>'http://www.sciencedirect.com/science/article/pii/S0092867408011872',
        '18692474'=>'http://www.sciencedirect.com/science/article/pii/S0092867408009380',
        '17701898'=>'http://www.sciencedirect.com/science/article/pii/S0002929707613494',
        '19251136'=>'http://www.sciencedirect.com/science/article/pii/S0886335008011620'
      })
  end

  test "journalofdairyscience" do
    calculate_pdf_urls_for_articles(Publisher::Journalofdairyscience.new,
      {
        '8436668' => 'http://download.journals.elsevierhealth.com/pdfs/journals/0022-0302/PIIS0022030293773282.pdf'
      })
  end

  test "ovid" do
    calculate_urls_for_articles(Publisher::Ovid.new,
      {
        # publisher requesting credentials as of 16th Sept 2011 jpmcgrath
        '20831298'=>"http://ovidsp.ovid.com/ovidweb.cgi?T=JS&PAGE=fulltext&CSC=y&D=ovft&MODE=ovid&NEWS=N&AN=00019053-201028100-00013"
      })
  end

  test "lww" do
    calculate_pdf_urls_for_articles(Publisher::LWW.new,
      {
        '18971675'=>"http://ovidsp.ovid.com/ovidweb.cgi?T=JS&PAGE=fulltext&CSC=y&D=ovft&MODE=ovid&NEWS=N&AN=01266029-200812000-00002"
      })
  end

  test "cdc" do
    calculate_pdf_urls_for_articles(Publisher::CDC.new,
      {
        '21900872'=>'http://www.cdc.gov/mmwr/pdf/wk/mm6035.pdf'
      })
  end

  test "wiley" do
    puts "wiley test"
    calculate_pdf_urls_for_articles(Publisher::Wiley.new,
      {
        '3124802'=>'http://onlinelibrary.wiley.com/doi/10.1111/j.1440-1754.1987.tb00284.x/pdf',
        '11920382'=>'http://onlinelibrary.wiley.com/doi/10.1002/ar.10057/pdf',
        '10825866'=>'http://onlinelibrary.wiley.com/doi/10.1111/j.1708-8240.1999.tb00414.x/pdf',
        'pgtmp_928e5799a14147f7c0e56dc508283bc3'=>'http://onlinelibrary.wiley.com/doi/10.1111/j.1463-6395.2009.00447.x/pdf',
        '12868962'=>'http://onlinelibrary.wiley.com/doi/10.1034/j.1600-0536.2003.00085.x/pdf',
        '21462167'=>'http://onlinelibrary.wiley.com/doi/10.1002/0471142735.im1425s93/pdf',
        '21462169'=>'http://onlinelibrary.wiley.com/doi/10.1002/0471142735.im1904s93/pdf',
        '15622516'=>'http://onlinelibrary.wiley.com/doi/10.1002/ar.a.20144/pdf'
      })
  end

  test "informahealthcare" do
    calculate_pdf_urls_for_articles(Publisher::Informahealthcare.new, {
      '18938777'=>'http://informahealthcare.com/doi/pdf/10.1080/00365520701559003',
      '18687167' => 'http://informahealthcare.com/doi/pdf/10.1185/03007990802352894'
    })
  end

  test 'orthosupersite' do
    calculate_urls_for_articles(Publisher::Orthosupersite.new,
      {
        '20415348'=>'http://www.orthosupersite.com/view.aspx?rid=62426'
      })
  end

  test 'aacp' do
    calculate_pdf_urls_for_articles(Publisher::Aacp.new,
      {
        '14971863'=>'http://www.springerlink.com/content/nk10g5w886122l76/fulltext.pdf',
        '21180658'=>'http://www.aacp.com/pdf%2F1110%2F1110ACP%5FSuris%2Epdf',
        '18568577'=>'http://www.portico.org/Portico/article/access/DownloadPDF.por?journalId=ISSN_10401237&issueId=ISSN_10401237v20i2&articleId=pf1m9kpzj3&fileType=pdf&fileValid=true'
      })

  end

  test 'mjm' do
    calculate_pdf_urls_for_articles(Publisher::Mjm.new,
      {
        '18551940'=>'http://www.e-mjm.org/2007/v62n4/Dengue_Virus_Chikungunya_Virus.pdf'
      })
  end

  test 'healthharvard' do
    calculate_urls_for_articles(Publisher::Healthharvard.new,
      {
        '20499461'=>'http://www.health.harvard.edu/newsletters/Harvard_Mens_Health_Watch/2010/April/food-borne-illnesses-part-ii-personal-protection'
      })
  end





  #  no pdf_url as of 16th Sept 2011 jpmcgrath
  test 'ammons' do
    calculate_urls_for_articles(Publisher::Ammons.new,
      {
        #  no results for search 'pdf_sources:ammons' as of 16th Sept 2011 jpmcgrath
        #        ''=>''
      })
        end

  test 'annual_reviews' do
    calculate_urls_for_articles(Publisher::AnnualReviews.new,
      {
        #  no results for search 'pdf_sources:annual_reviews' as of 16th Sept 2011 jpmcgrath
        #      ''=>''
      })
  end

  test 'atypon' do
    calculate_pdf_urls_for_articles(Publisher::Atypon.new,
      {
        '21728711'=>'http://www.atypon-link.com/doi/pdf/10.1521/ijgp.2011.61.3.469'
      })
  end

  test 'bioone' do
    calculate_pdf_urls_for_articles(Publisher::Bioone.new,
      {
        '21268706'=>'http://www.bioone.org/doi/pdf/10.1667/RRXX29.1'
      })
  end

  test 'bioscience' do
    calculate_pdf_urls_for_articles(Publisher::Bioscience.new,
      {
        '21196158'=>'http://www.bioscience.org/asp/getfile.asp?FileName=/2011/v16/af/3675/3675.pdf'
      })
  end

  test 'cambridge' do
    calculate_pdf_urls_for_articles(Publisher::Cambridge.new,
      {
      #  '9306887' => 'http://journals.cambridge.org/action/displayFulltext?pageCode=100101&type=1&fid=883200&jid=&aid=883192',
      #                #http://journals.cambridge.org/action/displayFulltext?type=1&pdftype=1&fid=883200&jid=BJN&volumeId=78&issueId=&aid=883192
      #                #http://journals.cambridge.org/action/displayFulltext?type=1&pdftype=1&fid=883080&jid=BJN&volumeId=78&issueId=&aid=883076
      #  '18826669'=> 'http://journals.cambridge.org/action/displayFulltext?pageCode=100101&type=1&fid=2335044&jid=&aid=2335036'
      #                http://journals.cambridge.org/action/displayFulltext?type=1&fid=2335044&jid=BBS&volumeId=31&issueId=05&aid=2335036&bodyId=&membershipNumber=&societyETOCSession=
      })
  end

  test 'cancerimmunity' do
    calculate_pdf_urls_for_articles(Publisher::Cancerimmunity.new,
      {
        # Github issue #104
        # Following error occurred when trying to get URL : undefined method `merge' for nil:NilClass
        '20108890'=>'http://www.cancerimmunity.org/v10p4/091213.pdf',
        '21090563'=>'http://www.cancerimmunity.org/v10p11/101111.pdf'
      })
  end


  test 'chicago' do
    calculate_pdf_urls_for_articles(Publisher::Chicago.new,
      {
        # All 5 pdf links that I checked did not lead to a pdf. jpmcgrath
        # ''=>''
      })
  end


  test 'copernicus' do
    calculate_pdf_urls_for_articles(Publisher::Copernicus.new,
      {
        #  no results for search 'pdf_sources:copernicus' as of 16th Sept 2011 jpmcgrath
        #      ''=>''
      })
  end


  test 'csa' do
    calculate_pdf_urls_for_articles(Publisher::CSA.new,
      {
        #  no results for search 'pdf_sources:csa' as of 16th Sept 2011 jpmcgrath
        #        ''=>''
      })
  end


  test 'ebsco' do
    calculate_pdf_urls_for_articles(Publisher::Ebsco.new,
      {
        # behind credentials wall
        #'pgtmp_260f8ac1901d41b0e0a1e7f0963a4850'=>'http://content.ebscohost.com.ezp-prod1.hul.harvard.edu/pdf25_26/pdf/2010/BMT/01Jun10/59820381.pdf'
      })
    end

  test 'eph' do
    calculate_pdf_urls_for_articles(Publisher::EPH.new,
      {
        # Geting 404 error
        # '21862444'=>'http://ehp03.niehs.nih.gov/article/fetchObject.action;?uri=info:doi/10.1289/ehp.1103711&representation=PDF'
      })
  end

  test 'future' do
    calculate_pdf_urls_for_articles(Publisher::Future.new,
      {
        #  no results for search 'pdf_sources:future' as of 16th Sept 2011 jpmcgrath
        #        ''=>''
      })
  end

  test 'gale' do
    calculate_pdf_urls_for_articles(Publisher::Gale.new,
      {
      #  no results for search 'pdf_sources:gale' as of 16th Sept 2011 jpmcgrath
      #  ''=>''
      })
  end

  test 'informaworld' do
    calculate_pdf_urls_for_articles(Publisher::Informaworld.new,
      {
        # All 5 pdf links that I checked did not lead to a pdf. jpmcgrath
        #      ''=>''
      })
  end

  test 'iop' do
    calculate_pdf_urls_for_articles(Publisher::IOP.new,
      {
        'pgtmp_11032944'=>'http://iopscience.iop.org/0295-5075/96/10001//pdf/0295-5075_96_10001_.pdf'
      })
  end

  #  no results for search 'pdf_sources:ismni' as of 16th Sept 2011 jpmcgrath
  test 'ismni' do
    calculate_pdf_urls_for_articles(Publisher::ISMNI.new,
      {
  #      ''=>''
      })
  end

  # this link dpes not seem to be a direct link to the pdf as of 16th Sept 2011 jpmcgrath
  test 'jbmr' do
    calculate_pdf_urls_for_articles(Publisher::JBMR.new,
      {
        '20205168'=>'http://onlinelibrary.wiley.com/doi/10.1002/jbmr.78/pdf'
      })
  end

  test 'jci' do
    calculate_pdf_urls_for_articles(Publisher::JCI.new,
      {
        '21841316'=>'http://www.jci.org/articles/view/45816/files/pdf'
      })
  end

  test 'jns' do
    calculate_pdf_urls_for_articles(Publisher::JNS.new,
      {
        '21284454'=>'http://thejns.org/doi/pdf/10.3171/2010.10.FOCUS10214'
      })
  end

  test 'jstage' do
    calculate_pdf_urls_for_articles(Publisher::Jstage.new,
      {
        '21187670'=>'http://www.jstage.jst.go.jp/article/jrr/52/1/1/_pdf'
      })
  end

  test 'jstor' do
    calculate_pdf_urls_for_articles(Publisher::Jstor.new,
      {
        # Github issue #105
        #'9240689'=>'http://www.jci.org/articles/view/41474/files/pdf'
      })
  end

  test 'korean_dermatology' do
    calculate_pdf_urls_for_articles(Publisher::KoreanDermatology.new,
      {
        #  no results for search 'pdf_sources:korean_dermatology' as of 16th Sept 2011 jpmcgrath
        #  ''=>''
      })
  end


  test 'krakow' do
    calculate_pdf_urls_for_articles(Publisher::Krakow.new,
      {
        #  all pdf links led to 404 as of 16th Sept 2011 jpmcgrath
        #      ''=>''
      })
  end

  #  all pdf links led to blank page as of 16th Sept 2011 jpmcgrath
  test 'landes' do
    calculate_pdf_urls_for_articles(Publisher::Landes.new,
      {
        # behind creds. Still to check code jpmcgrath
        #'21857162'=>'http://www.landesbioscience.com/journals/cc/StraussCC10-17.pdf'
      })
  end

  test 'lexis_nexis' do
    calculate_pdf_urls_for_articles(Publisher::LexisNexis.new,
      {
        #  no pdf_url as of 16th Sept 2011 jpmcgrath
        #        ''=>''
      })
  end

  test 'mayo' do
    calculate_pdf_urls_for_articles(Publisher::Mayo.new,
      {
        '20194149'=>'http://www.mayoclinicproceedings.com/content/85/3/e9.full.pdf'
      })
  end

  # url tested with harvard creds
  test 'mdconsult' do
    calculate_urls_for_articles(Publisher::Mdconsult.new, {
      '21187181' => 'http://www.mdconsult.com/das/article/body/jorg=journal&source=MI&sp=23847435/N/779937/1.html?issn=0002-9343'
    })
  end

  test 'minervamedica' do
    calculate_pdf_urls_for_articles(Publisher::Minervamedica.new,
      {
        # ArgumentError: Wrong number of arguments (2 for cache_pdf 0)
        # call to cache_pdf
        # '19881464'=>'http://assets0.pubget.com/pdf/19881464.pdf'
      })
  end

  test 'mit' do
    calculate_pdf_urls_for_articles(Publisher::MIT.new,
      {
        # behind credential wall, needs testing before checking in: jmcgrath
        #      '21291315'=>'http://www.mitpressjournals.org/doi/pdf/10.1162/jocn.2011.21637'
      })
    end

  test 'mja' do
    calculate_pdf_urls_for_articles(Publisher::MJA.new,
      {
        # harvard proxy does not give access to pdf
        #      ''=>''
      })
  end

  test 'mla' do
    calculate_pdf_urls_for_articles(Publisher::MLA.new,
      {
        # issue with pdf_url :  undefined method `[]' for false:FalseClass
        # '21753919'=>'http://www.pubmedcentral.nih.gov/picrender.fcgi?artid=PMC3133906&blobtype=pdf'
      })
  end


  test 'muse' do
    calculate_pdf_urls_for_articles(Publisher::Muse.new,
      {
        #  no results for search 'pdf_sources:muse' as of 16th Sept 2011 jpmcgrath
        #      ''=>''
      })
  end

  test 'oas' do
    calculate_pdf_urls_for_articles(Publisher::OAS.new,
      {
        # behind credwall, needs testing
        #'pgtmp_11054071'=>'http://www.opticsinfobase.org/josab/viewmedia.cfm?uri=josab-28-9-2165&seq=0'
      })
  end


  test 'phr' do
    calculate_pdf_urls_for_articles(Publisher::PHR.new,
      {
        #  no results for search 'pdf_sources:phr' as of 16th Sept 2011 jpmcgrath
        #      ''=>''
      })
  end

  test 'plos' do
    calculate_pdf_urls_for_articles(Publisher::Plos.new,
      {
        # Github issue #100
        # unexpected URL: should be:
        #              http://www.plosmedicine.org/article/fetchObjectAttachment.action?uri=info%3Adoi%2F10.1371%2Fjournal.pmed.1001091&representation=PDF
        # '21909249'=>'http://www.plosmedicine.org/article/fetchObjectAttachment.action;jsessionid=1527014175A813267D654AE186D28E89.ambra01?uri=info%3Adoi%2F10.1371%2Fjournal.pmed.1001091&representation=PDF'
      })
  end

  test 'portland' do
    calculate_pdf_urls_for_articles(Publisher::Portland.new,
      {
        # error: undefined method `rjust' for nil:NilClass
        #'21793802'=>'http://www.biochemj.org/bj/438/e001/438e001.pdf'
      })
  end


  test 'proquest' do
    calculate_pdf_urls_for_articles(Publisher::Proquest.new,
      {
        #  no results for search 'pdf_sources:phr' as of 16th Sept 2011 jpmcgrath
        #      ''=>''
      })
  end

  test 'psychiatry' do
    calculate_pdf_urls_for_articles(Publisher::Psychiatry.new,
      {
        # behind cred wall, needs testing
        # '20694119'=>'http://www.psychiatrist.com/private/pccpdf/2010/09m00817gry/09m00817gry.pdf'
      })
  end


  test 'publichealth' do
    calculate_pdf_urls_for_articles(Publisher::Publichealth.new,
      {
        #  no results for search 'pdf_sources:publichealth' as of 16th Sept 2011 jpmcgrath
        #      ''=>''
      })
  end

  test 'pubmedcentral' do
    calculate_pdf_urls_for_articles(Publisher::Pubmedcentral.new,
      {
        # no articles for pubmedcentral at 30 Sept 2011 - jpmcgrath
        #        ''=>''
      })
  end

  test 'rsp' do
    calculate_pdf_urls_for_articles(Publisher::RSP.new,
      {
        '20147314'=>'http://rsif.royalsocietypublishing.org/content/7/48/1119.full.pdf'
      })
  end

  test 'saudi' do
    calculate_pdf_urls_for_articles(Publisher::Saudi.new,
      {
        #  no results for search 'pdf_sources:saudi' as of 16th Sept 2011 jpmcgrath
        #      ''=>''
      })
  end

  test 'sleep' do
    calculate_pdf_urls_for_articles(Publisher::Sleep.new,
      {
        # 404 in pdf_url
        # '21203366'=>'http://www.pubmedcentral.nih.gov/picrender.fcgi?artid=PMC3001789&blobtype=pdf'
      })
  end


  test 'taylorandfrancis' do
    calculate_pdf_urls_for_articles(Publisher::Taylorandfrancis.new,
      {
        #  no results for search 'pdf_sources:taylorandfrancis' as of 16th Sept 2011 jpmcgrath
        #''=>''
      })
  end

  test 'thieme' do
    calculate_pdf_urls_for_articles(Publisher::Thieme.new,
      {
        # issue with pdf_url :  undefined method `[]' for false:FalseClass
        # '21229472'=>'https://www.thieme-connect.com/ejournals/pdf/endoscopy/doi/10.1055/s-0030-1256128.pdf'
      })
  end

  test 'westlaw' do
    calculate_pdf_urls_for_articles(Publisher::Westlaw.new,
      {
        #  no results for search 'pdf_sources:westlaw' as of 16th Sept 2011 jpmcgrath
        #        ''=>''
      })
  end

  test 'wjgnet' do
    calculate_pdf_urls_for_articles(Publisher::Wjgnet.new,
      {
        '21218084'=>'http://www.wjgnet.com/1007-9327/17/53.pdf'
      })
  end

  test 'aaas' do
    calculate_pdf_urls_for_articles(Publisher::Aaas.new,
      {
        #  no results for search 'pdf_sources:aaas' as of 16th Sept 2011 jpmcgrath
        #        ''=>''
      })
  end

  test 'aacr' do
    calculate_pdf_urls_for_articles(Publisher::Aacr.new,
      {
        # no results for search 'pdf_sources:aacr' as of 16th Sept 2011 jpmcgrath
        #''=>''
      })
  end

  test 'aaidd' do
    calculate_pdf_urls_for_articles(Publisher::Aaidd.new,
      {
        # no results for search 'pdf_sources:aaidd' as of 16th Sept 2011 jpmcgrath
        #        ''=>''
      })
  end

  test 'ada' do
    calculate_pdf_urls_for_articles(Publisher::ADA.new,
      {
        # no results for search 'pdf_sources:ada' as of 16th Sept 2011 jpmcgrath
        #        ''=>''
      })
  end

  test 'asm' do
    calculate_pdf_urls_for_articles(Publisher::Asm.new,
      {
        '21911575'=>'http://aac.asm.org/cgi/reprint/AAC.05101-11v1.pdf'
      })
  end

  test 'oxfordjournals' do
    calculate_pdf_urls_for_articles(Publisher::Oxford.new,
      {
        '1431253'=>'http://jid.oxfordjournals.org/content/166/6/1354.full.pdf'
      })
  end

  test 'endojournals' do
    calculate_pdf_urls_for_articles(Publisher::Endojournals.new,
      {
        '7539819'=>'http://jcem.endojournals.org/content/80/6/1941.full.pdf'
      })
  end

  test 'sage' do
    calculate_pdf_urls_for_articles(Publisher::Sage.new,
      {
        'pgtmp_jstor3081818'=>'http://gas.sagepub.com/content/17/1/122.full.pdf'
      })
  end

  test 'ncbi' do
    calculate_pdf_urls_for_articles(Publisher::Ncbi.new,
      {
        '19949538'=>'http://www.ncbi.nlm.nih.gov/pmc/articles/PMC2695355/pdf/jaba-42-02-469.pdf'
      })
  end

  test 'molvis' do
    calculate_pdf_urls_for_articles(Publisher::Molvis.new,
      {
        '20454694'=>'http://www.molvis.org/molvis/v16/a85/mv-v16-a85-bee.pdf'
      })
  end

  test 'pathexo' do
    calculate_pdf_urls_for_articles(Publisher::Pathexo.new,
      {
        '18956807'=>'http://www.pathexo.fr/documents/articles-bull/T101-4-3132.pdf'
      })
  end

  test 'brazjurol' do
    calculate_pdf_urls_for_articles(Publisher::Brazjurol.new,
      {
        '19719856'=>'http://www.brazjurol.com.br/july_august_2009/Park_416_426.pdf',
        '19719857'=>'http://www.brazjurol.com.br/july_august_2009/Srougi_427_431.pdf',
        '19719858'=>'http://www.brazjurol.com.br/july_august_2009/Matos_432_435.pdf',
        '19719859'=>'http://www.brazjurol.com.br/july_august_2009/Tsivian_436_441.pdf',
        '19719860'=>'http://www.brazjurol.com.br/july_august_2009/Lumen_442_449.pdf',
        '19719861'=>'http://www.brazjurol.com.br/july_august_2009/Elgammal_450_458.pdf',
        '19719862'=>'http://www.brazjurol.com.br/july_august_2009/Macedo_459_466.pdf'
      })
  end

  test 'seameo' do
    calculate_pdf_urls_for_articles(Publisher::Seameo.new,
      {
        '20578514'=>'http://www.tm.mahidol.ac.th/seameo/2010-41-2/08-4542.pdf'
      })
  end

  test 'ijmr' do
    calculate_pdf_urls_for_articles(Publisher::Ijmr.new,
      {
        '16177464'=>'http://www.icmr.nic.in/ijmr/2005/august/commentary2.pdf'
      })
  end

  test 'scielo' do
    calculate_pdf_urls_for_articles(Publisher::Scielo.new,
      {
        '17546315'=>'http://www.scielosp.org/pdf/bwho/v85n4/a19v85n4.pdf',
        '19831318'=>'http://www.scielo.org.ar/pdf/ram/v41n3/v41n3a11.pdf',
        '16547577'=>'http://www.scielo.br/pdf/rimtsp/v48n1/28197.pdf'
      })
  end

  test 'medicinaoral' do
    calculate_pdf_urls_for_articles(Publisher::Medicinaoral.new,
      {
        '20526267'=>'http://www.medicinaoral.com/pubmed/medoralv16_i1_p42.pdf'
      })
  end

  test 'crd' do
    calculate_pdf_urls_for_articles(Publisher::Crd.new,
      {
        '19638254'=>'http://update-sbs.update.co.uk/CMS2Web/tempPDF/12010002124.pdf'
      })
  end

  test 'sladen' do
    calculate_pdf_urls_for_articles(Publisher::Sladen.new,
      {
        '21449516'=>'http://www.henryfordconnect.com/documents/Sladen%20Library/HBQI-March2011.pdf'
      })
  end

  test 'schattauer' do
    calculate_pdf_urls_for_articles(Publisher::Schattauer.new,
      {
        '20135063'=>'http://www.schattauer.de/de/magazine/uebersicht/zeitschriften-a-z/thrombosis-and-haemostasis/contents/archive/issue/special/manuscript/12599/download.html'
      })
  end

  test 'oie' do
    calculate_pdf_urls_for_articles(Publisher::Oie.new,
      {
        '20128478'=>'http://web.oie.int/boutique/extrait/28stoddard671680.pdf'
      })
  end

  test 'karger' do
    calculate_pdf_urls_for_articles(Publisher::Karger.new,
      {
        '21677440'=>'http://content.karger.com/ProdukteDB/produkte.asp?Aktion=ShowPDF&ArtikelNr=324653&Ausgabe=255031&ProduktNr=228539&filename=324653.pdf'
      })
  end

  test 'uchile' do
    calculate_pdf_urls_for_articles(Publisher::Uchile.new,
      {
        'pgtmp_b7b9a9cb7b97af23b7bf1ccaef64c156'=>'http://captura.uchile.cl/jspui/bitstream/2250/10743/1/Bruhat_Comm_Alg_2008.pdf'
      })
  end

  test 'mdpi' do
    calculate_pdf_urls_for_articles(Publisher::MDPI.new,
      {
        '19924061'=>'http://www.mdpi.com/1420-3049/14/10/4246/pdf'
      })
  end

  test 'nefrologia' do
    calculate_pdf_urls_for_articles(Publisher::Nefrologia.new,
      {
        '21468162'=>'http://www.revistanefrologia.com/revistas/P1-E521/P1-E521-S2948-A10870-EN.pdf'
      })
  end

  test 'hindawi' do
    calculate_pdf_urls_for_articles(Publisher::Hindawi.new,
      {
        '21577271'=>'http://downloads.hindawi.com/journals/jtran/2011/389542.pdf'
      })
  end

  test 'ingenta' do
    calculate_urls_for_articles(Publisher::Ingenta.new,
      {
        '17853691'=>'http://www.ingentaconnect.com/content/maik/bibu/2007/00000034/00000003/00003005'
      })
  end

  test 'medind' do
    calculate_pdf_urls_for_articles(Publisher::Medind.new,
      {
        '18174655'=>'http://medind.nic.in/icb/t07/i12/icbt07i12p1131.pdf'
      })
  end

  test 'soils' do
    calculate_pdf_urls_for_articles(Publisher::Soils.new,
      {
        '18299598'=>'https://www.soils.org/publications/jeq/pdfs/37/2/631'
      })
  end

  test 'indianjnephrol' do
    calculate_pdf_urls_for_articles(Publisher::Indianjnephrol.new,
      {
        '20368923'=>'http://www.indianjnephrol.org/article.asp?issn=0971-4065;year=2009;volume=19;issue=2;spage=48;epage=52;aulast=Das'
      })
  end

  #test 'proquest' do

  #end
  
  #################################################################################################

  def calculate_urls_for_articles(pub_class, params)
    params.keys.each do |pmid|
      puts "\nTesting PMID: #{pmid}\n"

      #Article Info
      article = Article.find_by_pmid(pmid)

      # Calculate article's pdf path
      article.calculate_pdf_url(pub_class)

      # Assertions
      assert (not article.url.blank?), "#{pmid}: Expected to get some value for url."
      if params[pmid].is_a?(String)
        assert params[pmid] == article.url.to_s, "#{pmid}: Expected url to be '#{params[pmid]}' but got '#{article.url.to_s}'"
      elsif params[pmid].is_a?(Regexp)
        assert_match params[pmid], article.url.to_s, "#{pmid}: Expected url to match #{params[pmid]} but got #{article.url.to_s}"
      end
    end
  end

  def calculate_pdf_urls_for_articles(pub_class, params)
    params.keys.each do |pmid|
      puts "\nTesting PMID: #{pmid}\n"

      #Article Info
      article = Article.find_by_pmid(pmid)

      # Calculate article's pdf path
      pdf_url = article.calculate_pdf_url(pub_class)

      # Assertions
      assert (not pdf_url.blank?), "#{pmid}: Expected to get some value for pdf_url."
      if params[pmid].is_a?(String)
        assert params[pmid] == pdf_url.to_s, "#{pmid}: Expected pdf_url to be '#{params[pmid]}' but got '#{pdf_url.to_s}'"
      elsif params[pmid].is_a?(Regexp)
        assert_match params[pmid], pdf_url.to_s, "#{pmid}: Expected pdf_url to match #{params[pmid]} but got #{pdf_url.to_s}"
      end
    end
  end
end

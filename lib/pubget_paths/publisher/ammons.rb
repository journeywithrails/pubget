class Publisher::Ammons < Publisher::Atypon

  def openurl(params)
     article = params[:article]
     doi = article.get_doi(params)
     return  doi  ? "http://www.amsciepub.com/doi/abs/#{doi}" : nil
   end
end
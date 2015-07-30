// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

import
  javax.inject.Inject

import
  play.{ api, filters },
    api.{ http, mvc },
      http.HttpFilters,
      mvc.EssentialFilter,
    filters.cors.CORSFilter

class Filters @Inject() (corsFilter: CORSFilter) extends HttpFilters {
  override def filters: Seq[EssentialFilter] = Seq(corsFilter)
}

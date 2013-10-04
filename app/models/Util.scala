package models

import
  scala.io.{ BufferedSource, Source }

object Util {

  def using[A <: { def close() }, B](closeable: A)(f: A => B): B =
    try f(closeable) finally closeable.close()

  def usingSource[T](sourceBuildFunc: (Source.type) => BufferedSource)(sourceProcessFunc: (BufferedSource) => T): T =
    using(sourceBuildFunc(Source))(sourceProcessFunc)

  def noneIfEmpty[T <% { def isEmpty: Boolean }](x: T): Option[T] = if (!x.isEmpty) Option(x) else None

}

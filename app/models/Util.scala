// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package models

import
  java.io.Closeable

import
  scala.{ collection, io },
    collection.GenIterable,
    io.{ BufferedSource, Source }

object Util {

  def using[A <: Closeable, B](closeable: A)(f: A => B): B =
    try f(closeable) finally closeable.close()

  def usingSource[A <: BufferedSource, B](closeable: A)(f: A => B): B =
    try f(closeable) finally closeable.close()

  def usingSource[T](sourceBuildFunc: (Source.type) => BufferedSource)(sourceProcessFunc: (BufferedSource) => T): T =
    usingSource(sourceBuildFunc(Source))(sourceProcessFunc)

  def noneIfEmpty[S, T[S] <: GenIterable[S]](x: T[S]): Option[T[S]] = if (!x.isEmpty) Option(x) else None

}

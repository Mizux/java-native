package org.mizux.javanative;

import org.mizux.javanative.Loader;
import org.mizux.javanative.foo.Foo;
import org.mizux.javanative.foo.Globals;
import org.mizux.javanative.foo.StringVector;
import org.mizux.javanative.foo.StringJaggedArray;
import org.mizux.javanative.foo.IntPair;
import org.mizux.javanative.foo.PairVector;
import org.mizux.javanative.foo.PairJaggedArray;
import java.util.AbstractList;

/**
 * @author Mizux
 */
public class Test {
  private static void testFreeFunctions() {
    try {
      Globals.freeFunction(32);
      Globals.freeFunction((long)64);
    } catch (Exception ex) {
      throw new RuntimeException(ex);
    }
  }

  private static void testStaticMethods() {
    try {
      Foo.staticFunction(32);
      Foo.staticFunction((long)64);
    } catch (Exception ex) {
      throw new RuntimeException(ex);
    }
  }

  private static void testStringVector() {
    try {
      {
        StringVector result = Globals.stringVectorOutput(5);
        System.out.printf("result.size(): %d\n", result.size());
        System.out.printf("{");
        for(int i=0; i < result.size(); ++i) {
          System.out.printf("%s, ", result.get(i));
        }
        System.out.printf("}\n");
      }
      {
        AbstractList<String> result = Globals.stringVectorOutput(5);
        System.out.printf("result.size(): %d\n", result.size());
        System.out.printf("{");
        for(int i=0; i < result.size(); ++i) {
          System.out.printf("%s, ", result.get(i));
        }
        System.out.printf("}\n");
      }
    } catch (Exception ex) {
      throw new RuntimeException(ex);
    }
  }

  private static void testStringJaggedArray() {
    try {
      {
        AbstractList<StringVector> result = Globals.stringJaggedArrayOutput(5);
        System.out.printf("result.size(): %d\n", result.size());
        System.out.printf("{");
        for(int i=0; i < result.size(); ++i) {
          System.out.printf("{");
          AbstractList<String> inner = result.get(i);
          for(int j=0; j < inner.size(); ++j) {
            System.out.printf("%s,", inner.get(j));
          }
          System.out.printf("},");
        }
        System.out.printf("}\n");
      }
      {
        StringVector vec1 = new StringVector(new String[]{"1", "2", "3"});
        StringVector vec2 = new StringVector(new String[]{"4", "5"});
        StringJaggedArray jag = new StringJaggedArray(new StringVector[]{vec1, vec2});
        Globals.stringJaggedArrayInput(jag);
        Globals.stringJaggedArrayRefInput(jag);
      }
    } catch (Exception ex) {
      throw new RuntimeException(ex);
    }
  }

  private static void testPairVector() {
    try {
      {
        PairVector result = Globals.pairVectorOutput(5);
        System.out.printf("result.size(): %d\n", result.size());
        System.out.printf("{");
        for(int i=0; i < result.size(); ++i) {
          IntPair p = result.get(i);
          System.out.printf("[%d,%d], ", p.getFirst(), p.getSecond());
        }
        System.out.printf("}\n");
      }
      {
        AbstractList<IntPair> result = Globals.pairVectorOutput(5);
        System.out.printf("result.size(): %d\n", result.size());
        System.out.printf("{");
        for(int i=0; i < result.size(); ++i) {
          IntPair p = result.get(i);
          System.out.printf("[%d,%d], ", p.getFirst(), p.getSecond());
        }
        System.out.printf("}\n");
      }
    } catch (Exception ex) {
      throw new RuntimeException(ex);
    }
  }

  private static void testPairJaggedArray() {
    try {
      {
        AbstractList<PairVector> result = Globals.pairJaggedArrayOutput(5);
        System.out.printf("result.size(): %d\n", result.size());
        System.out.printf("{");
        for(int i=0; i < result.size(); ++i) {
          System.out.printf("{");
          AbstractList<IntPair> inner = result.get(i);
          for(int j=0; j < inner.size(); ++j) {
            System.out.printf("[%d,%d],", inner.get(j).getFirst(), inner.get(j).getSecond());
          }
          System.out.printf("},");
        }
        System.out.printf("}\n");
      }
      {
        PairVector vec1 = new PairVector(new IntPair[]{new IntPair(1,1), new IntPair(2,2), new IntPair(3,3)});
        PairVector vec2 = new PairVector(new IntPair[]{ new IntPair(4,4), new IntPair(5,5) });
        PairJaggedArray jag = new PairJaggedArray(new PairVector[]{vec1, vec2});
        Globals.pairJaggedArrayInput(jag);
        Globals.pairJaggedArrayRefInput(jag);
      }
    } catch (Exception ex) {
      throw new RuntimeException(ex);
    }
  }

  private static void testFoo() {
    try {
      Foo f = new Foo();
      f.setInt(32);
      System.out.printf("Foo int: %d\n", f.getInt());

      f.setInt64((long)64);
      System.out.printf("Foo int64: %d\n", f.getInt64());
    } catch (Exception ex) {
      throw new RuntimeException(ex);
    }
  }

  public static void main(String[] args) {
    Loader.loadNativeLibraries();
    testFreeFunctions();
    testStaticMethods();

    testStringVector();
    testStringJaggedArray();

    testPairVector();
    testPairJaggedArray();

    testFoo();
  }
}


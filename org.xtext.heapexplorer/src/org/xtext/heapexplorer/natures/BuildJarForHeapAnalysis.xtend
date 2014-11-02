package org.xtext.heapexplorer.natures

import org.eclipse.core.resources.IncrementalProjectBuilder
import java.util.Map
import org.eclipse.core.runtime.IProgressMonitor
import org.eclipse.core.runtime.CoreException
import org.eclipse.core.resources.IResourceDelta
import org.eclipse.core.resources.IResourceDeltaVisitor
import org.eclipse.core.resources.IResource
import org.eclipse.core.runtime.Path
import org.eclipse.core.resources.IContainer
import java.io.FileOutputStream
import java.util.jar.Manifest
import java.util.jar.JarOutputStream
import java.io.FilenameFilter
import java.io.File
import java.util.jar.JarEntry
import java.io.FileInputStream
import org.apache.log4j.Logger

class BuildJarForHeapAnalysis extends IncrementalProjectBuilder {
	
	private static final Logger log = Logger.getLogger(typeof(BuildJarForHeapAnalysis))
	
	override protected build(int kind, Map<String, String> args, IProgressMonitor monitor) throws CoreException {
		if (kind == IncrementalProjectBuilder.FULL_BUILD) { } else {
			val IResourceDelta delta = getDelta(getProject())
			if (delta != null) {
				incrementalBuild(delta, monitor)
			}
		}
		return null;
	}
	
	def incrementalBuild(IResourceDelta delta, IProgressMonitor monitor) {
		delta.accept(new MyBuildResourceDeltaVisitor())
	}
	
	static class MyBuildResourceDeltaVisitor implements IResourceDeltaVisitor {
		override visit(IResourceDelta delta) throws CoreException {
			try {
				val IResource res = delta.getResource()
				if (res.name.equals("src-gen")) {
					return false
				} else {
					if ("he".equals(res.getFileExtension())) {
						val analysis = res.getName().substring(0,
								res.getName().lastIndexOf('.'));
						val p = new Path("src-gen/" + analysis);
						val IContainer c = res.getProject().getFolder(p);
						if (!c.exists())
							return false;
						val binfolder = res.getProject().getFolder("bin");
						if (binfolder.exists()) {
							val byte[] buffer = newByteArrayOfSize(4096)
							val jar = c.getFile(new Path('''«analysis».jar'''))
							val stream = new FileOutputStream(jar.location.toFile)
							val jarStream = new JarOutputStream(stream, new Manifest())
							val analysisFolder = binfolder.getFolder(analysis)
							log.error('''THE GUY IS «analysisFolder.location»''')
							
							if (analysisFolder.exists) {
								binfolder.getFolder(analysis).location.toFile.listFiles(new FilenameFilter() {
									override accept(File dir, String name) {
										name != null && name.endsWith(".class")
									}
								}).forEach[
									val JarEntry jarAdd = new JarEntry('''«analysis»/«it.name»''')
		        					jarAdd.setTime(it.lastModified())
		        					jarStream.putNextEntry(jarAdd);
		        					val in = new FileInputStream(it)
		        					var int nRead = in.read(buffer, 0, buffer.length)
							        while (nRead > 0) {
							          jarStream.write(buffer, 0, nRead);
							          nRead = in.read(buffer, 0, buffer.length)
							        }
							        in.close
								]
								jarStream.close
							}
						}
						return false;
					}
					return true
				}
			}
			catch (Exception ex) {
				ex.printStackTrace
				throw ex;
			}
		} // end of method definition
		
	} // end of class definition
}


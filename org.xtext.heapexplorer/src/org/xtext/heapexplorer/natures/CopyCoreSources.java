package org.xtext.heapexplorer.natures;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Enumeration;
import java.util.List;
import java.util.Map;

import javax.tools.JavaCompiler;

import org.apache.log4j.Logger;
import org.eclipse.core.resources.IContainer;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IFolder;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IncrementalProjectBuilder;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.Path;
import org.eclipse.jdt.core.IClasspathEntry;
import org.eclipse.jdt.core.IJavaProject;
import org.eclipse.jdt.core.JavaCore;
import org.osgi.framework.Bundle;
import org.osgi.framework.FrameworkUtil;

public class CopyCoreSources extends IncrementalProjectBuilder {

	private static final Logger log = Logger.getLogger(CopyCoreSources.class);
	
	
	@Override
	protected IProject[] build(int kind, Map<String, String> args,
			IProgressMonitor monitor) throws CoreException {
		IFolder folder = getProject().getFolder("src-gen");
		if (!folder.exists()) {
			folder.create(true, true, monitor);
			folder.setDerived(true, monitor);
			IJavaProject ijProject = JavaCore.create(getProject());
			List<IClasspathEntry> l = new ArrayList<>(Arrays.asList(ijProject.getRawClasspath()));
			l.add(JavaCore.newSourceEntry(ijProject.getPath().append("src-gen")));
			ijProject.setRawClasspath(l.toArray(new IClasspathEntry[l.size()]), monitor);
			
		}
		folder = folder.getFolder("core");
		if (!folder.exists()) {
			folder.create(true, true, monitor);
		}
		// generating common core. 
		// TODO: only if necessary
		Bundle bundle = FrameworkUtil.getBundle(getClass());
		String pathToResources = "resources/c";
		String corePath = "/core/";
		Enumeration<URL> l = bundle.findEntries(pathToResources,"*", true);
		while (l!=null && l.hasMoreElements()) {
			URL e = l.nextElement();
			String path = e.getPath().substring(("/" + pathToResources).length());
			IFile file = folder.getFile(path);
			if (!file.exists()) {
				InputStream input;
				try {
					input = e.openStream();
					file.create(input, true, monitor);
					input.close();
				} catch (IOException e1) {
					// TODO Auto-generated catch block
					e1.printStackTrace();
				}
				
			}
		}
		return null;
	}

}

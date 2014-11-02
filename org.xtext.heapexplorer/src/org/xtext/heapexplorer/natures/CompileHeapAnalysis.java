package org.xtext.heapexplorer.natures;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.URL;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Enumeration;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import javax.tools.JavaCompiler;

import org.apache.log4j.Logger;
import org.eclipse.core.resources.IContainer;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IFolder;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.resources.IResourceDelta;
import org.eclipse.core.resources.IResourceDeltaVisitor;
import org.eclipse.core.resources.IResourceVisitor;
import org.eclipse.core.resources.IncrementalProjectBuilder;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.Path;
import org.eclipse.jdt.core.IClasspathEntry;
import org.eclipse.jdt.core.IJavaProject;
import org.eclipse.jdt.core.JavaCore;
import org.eclipse.jdt.launching.IVMInstall;
import org.eclipse.jdt.launching.JavaRuntime;
import org.eclipse.ui.console.ConsolePlugin;
import org.eclipse.ui.console.IConsole;
import org.eclipse.ui.console.IConsoleManager;
import org.eclipse.ui.console.MessageConsole;
import org.eclipse.xtext.util.StringInputStream;
import org.osgi.framework.Bundle;
import org.osgi.framework.FrameworkUtil;

public class CompileHeapAnalysis extends IncrementalProjectBuilder {

	private static final Logger log = Logger
			.getLogger(CompileHeapAnalysis.class);

	class MyBuildVisitor implements IResourceVisitor {

		@Override
		public boolean visit(IResource resource) throws CoreException {
			if (resource.getName().equals("src-gen")) {
				log.error("Compiling full");
				return false;
			}
			return true;
		}

	}

	class MyBuildResourceDeltaVisitor implements IResourceDeltaVisitor {

		@Override
		public boolean visit(IResourceDelta delta) throws CoreException {
			String pathToStuff = getProject().getPersistentProperty(HeapExplorerNature.KEY_PATH_HE);
			if (pathToStuff == null) {
				// error
				return false;
			}
			IResource res = delta.getResource();
			if (res.getName().equals("src-gen")) {
				return false;
			} else {
				if ("he".equals(res.getFileExtension())) {
					String analysis = res.getName().substring(0,
							res.getName().lastIndexOf('.'));
					Path p = new Path("src-gen/" + analysis);
					IContainer c = getProject().getFolder(p);
					if (!c.exists())
						return false;
					IFile makefile = c.getFile(new Path("Makefile"));
					if (!makefile.exists()) {

						StringBuilder sBuilder = new StringBuilder();
						sBuilder.append("include ../core/subdir.mk\n\n");
						sBuilder.append(String.format("SRCS+=%s.c\n\n",
								analysis));
						sBuilder.append(String.format(
								"ANALYSIS_LIB:=lib%s.so\n\n", analysis));
						sBuilder.append(String.format("CFLAGS+=-I\"%s\"\n\n",
								pathToStuff));
						Path p0 = new Path(getProject().getLocation()
								.toString() + "/src-gen/core");
						sBuilder.append(String.format(
								"CFLAGS+=-I\"%s\"\n\n",p0));
						sBuilder.append(String.format("CFLAGS+=-I\"%s\"\n\n",
								c.getLocation()));
						sBuilder.append(String.format("LDFLAGS+=-L\"%s\"\n\n",
								pathToStuff));
						sBuilder.append("include ../core/makerules.mk\n");
						StringInputStream sis = new StringInputStream(
								sBuilder.toString());
						makefile.create(sis, true, null);

					}

					IFile additionalInclude = c.getFile(new Path(
							"delegateHeader.h"));
					if (!additionalInclude.exists()) {
						StringBuilder sBuilder = new StringBuilder();
						sBuilder.append(String.format("#include \"%s.h\"\n",
								analysis));
						StringInputStream sis = new StringInputStream(
								sBuilder.toString());
						additionalInclude.create(sis, true, null);
					}

					executeMakeTarget("installplugins", c.getLocation().toFile());
					return false;
				}
			}
			return true;
		}

	}
	
	private void executeMakeTarget(String target, File makefileDirectory) {
		IJavaProject ppp = JavaCore.create(getProject());
		IVMInstall vmInstall = null;
		try {
			vmInstall = JavaRuntime.getVMInstall(ppp);
		} catch (CoreException e1) { }
		if (vmInstall == null)
			vmInstall = JavaRuntime.getDefaultVMInstall();
		
		MessageConsole console = findConsole("HeapExplorer");
		console.activate();
		ProcessBuilder pb = new ProcessBuilder("make",
				String.format("JDK=%s", vmInstall.getInstallLocation()), 
				"OSNAME=linux",
				target);
		pb.directory(makefileDirectory);
		pb.redirectErrorStream(true);
		try {
			Process pr = pb.start();
			BufferedReader br = new BufferedReader(
					new InputStreamReader(pr.getInputStream()));
			String line = null;
			while ((line = br.readLine()) != null) {
				console.newMessageStream().println(line);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private MessageConsole findConsole(String name) {
		ConsolePlugin plugin = ConsolePlugin.getDefault();
		IConsoleManager conMan = plugin.getConsoleManager();
		IConsole[] existing = conMan.getConsoles();
		for (int i = 0; i < existing.length; i++)
			if (name.equals(existing[i].getName()))
				return (MessageConsole) existing[i];
		// no console found, so create a new one
		MessageConsole myConsole = new MessageConsole(name, null);
		conMan.addConsoles(new IConsole[] { myConsole });
		return myConsole;
	}

	protected void fullBuild(final IProgressMonitor monitor)
			throws CoreException {
		try {
			getProject().accept(new MyBuildVisitor());
		} catch (CoreException e) {
		}
	}

	protected void incrementalBuild(IResourceDelta delta,
			IProgressMonitor monitor) throws CoreException {
		// the visitor does the work.
		delta.accept(new MyBuildResourceDeltaVisitor());
	}

	@Override
	protected IProject[] build(int kind, Map<String, String> args,
			IProgressMonitor monitor) throws CoreException {

		if (kind == IncrementalProjectBuilder.FULL_BUILD) {
			fullBuild(monitor);
		} else {
			IResourceDelta delta = getDelta(getProject());
			if (delta == null) {
				fullBuild(monitor);
			} else {
				incrementalBuild(delta, monitor);
			}
		}
		return null;
	}
	

	@Override
	protected void clean(IProgressMonitor monitor) throws CoreException {
		super.clean(monitor);
		final List<IResource> l = new LinkedList<>();
		getProject().getFolder("src-gen").accept(new IResourceVisitor() {
			@Override
			public boolean visit(IResource resource) throws CoreException {
				if ("o".equals(resource.getFileExtension()))
					l.add(resource);
				else if ("so".equals(resource.getFileExtension()))
					l.add(resource);
				else if ("Makefile".equals(resource.getName()))
					l.add(resource);
				else if ("delegateHeader.h".equals(resource.getName()))
					l.add(resource);
				return true;
			}
		});
		for (IResource r: l) r.delete(true, monitor);
	}
	
	
	

}

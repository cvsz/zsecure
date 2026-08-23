"use strict";
let csrfToken = null;
const statusEl = document.getElementById("status");
function show(message) { statusEl.textContent = typeof message === "string" ? message : JSON.stringify(message, null, 2); }
async function api(path, options = {}) {
  const headers = new Headers(options.headers || {});
  if (options.body && !headers.has("Content-Type")) headers.set("Content-Type", "application/json");
  if (csrfToken && ["POST", "PUT", "PATCH", "DELETE"].includes((options.method || "GET").toUpperCase())) headers.set("X-CSRF-Token", csrfToken);
  const response = await fetch(path, {...options, headers, credentials: "same-origin"});
  if (response.status === 204) return null;
  const data = await response.json().catch(() => ({detail: "Unexpected response"}));
  if (!response.ok) throw new Error(data.detail || "Request failed");
  return data;
}
document.getElementById("register-form").addEventListener("submit", async (event) => { event.preventDefault(); try { show(await api("/register", {method:"POST", body:JSON.stringify({email:document.getElementById("register-email").value,password:document.getElementById("register-password").value})})); } catch (error) { show(error.message); } });
document.getElementById("login-form").addEventListener("submit", async (event) => { event.preventDefault(); try { const result=await api("/login", {method:"POST", body:JSON.stringify({email:document.getElementById("login-email").value,password:document.getElementById("login-password").value})}); csrfToken=result.csrf_token; show({authenticated:true}); } catch(error) { csrfToken=null; show(error.message); } });
document.getElementById("logout").addEventListener("click", async () => { try { await api("/logout", {method:"POST"}); csrfToken=null; show("Logged out"); } catch(error) { show(error.message); } });
document.getElementById("note-form").addEventListener("submit", async (event) => { event.preventDefault(); try { show(await api("/notes", {method:"POST", body:JSON.stringify({title:document.getElementById("note-title").value,body:document.getElementById("note-body").value})})); } catch(error) { show(error.message); } });

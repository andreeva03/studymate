defmodule StudymateWeb.FlashcardLive.Index do
  use StudymateWeb, :live_view
  alias Studymate.Study
  alias Studymate.Study.Flashcard
  alias Studymate.Accounts
  alias Studymate.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    flashcards = Study.list_flashcards()
    
    # Dynamically extract decks from existing cards
    decks = ["All Decks" | (flashcards |> Enum.map(& &1.category) |> Enum.uniq() |> Enum.sort())]
    
    # Mock data for Heatmap (Intensity 0-4)
    heatmap_data = for _ <- 1..84, do: Enum.random(0..4)

    # Mock Leaderboard Data
    leaderboard_data = [
      %{rank: 1, name: "AlexDev", streak: 45, xp: 1250},
      %{rank: 2, name: "SarahCode", streak: 32, xp: 980},
      %{rank: 3, name: "ElixirFan", streak: 28, xp: 850},
      %{rank: 4, name: "RubyGem", streak: 12, xp: 620},
      %{rank: 5, name: "NodeMaster", streak: 5, xp: 410}
    ]

    {:ok,
     socket
     |> assign(:page_title, "Studymate")
     |> assign(:flashcards, flashcards)
     |> assign(:decks, decks)
     |> assign(:current_deck, "All Decks")
     |> assign(:current_index, 0)
     |> assign(:is_flipped, false)
     |> assign(:active_tab, "home") 
     |> assign(:quiz_mode, "mcq") 
     |> assign(:quiz_feedback, nil) 
     |> assign(:mcq_options, [])
     |> assign(:search_query, "")
     |> assign(:type_input, "")
     |> assign(:bulk_input, "")
     |> assign(:session_stats, %{correct: 0, total: 0})
     |> assign(:timer_seconds, 0)
     |> assign(:form, to_form(Study.change_flashcard(%Flashcard{})))
     # User & Auth State
     |> assign(:current_user, nil)
     |> assign(:auth_modal, nil)
     |> assign(:auth_form, to_form(Accounts.change_user(%User{})))
     # Social State
     |> assign(:room_code, nil)
     |> assign(:players, [])
     |> assign(:is_public, false)
     |> assign(:share_link, nil)
     # Analytics & Theme
     |> assign(:heatmap_data, heatmap_data)
     |> assign(:leaderboard_data, leaderboard_data)
     |> assign(:dark_mode, false) # Default to light, toggle available
     |> assign(:reverse_mode, false)}
  end

  @impl
  def handle_info(:tick, socket) do
    {:noreply, assign(socket, timer_seconds: socket.assigns.timer_seconds + 1)}
  end

  @impl
  def render(assigns) do
    ~H"""
    <style>
      body {
        background-color: <%= if @dark_mode, do: "black", else: "#f8fafc" %> !important;
        transition: background-color 0.5s ease;
      }
      .heatmap-cell { width: 10px; height: 10px; border-radius: 2px; }
      .intensity-0 { background-color: <%= if @dark_mode, do: "#1a1a1a", else: "#ebedf0" %>; }
      .intensity-1 { background-color: #9be9a8; }
      .intensity-2 { background-color: #40c463; }
      .intensity-3 { background-color: #30a14e; }
      .intensity-4 { background-color: #216e39; }
    </style>

    <div class={"min-h-screen w-full p-4 md:p-8 font-sans transition-colors duration-500 " <> if @dark_mode, do: "bg-black text-slate-100", else: "bg-slate-50 text-slate-900"} id="study-app-root">
      
      <!-- AUTH MODALS -->
      <%= if @auth_modal do %>
        <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
          <div class={"relative w-full max-w-md p-8 rounded-[2rem] shadow-2xl animate-in zoom-in-95 duration-200 " <> if @dark_mode, do: "bg-slate-900 border border-slate-700", else: "bg-white"}>
            <button phx-click="close_auth" class="absolute top-6 right-6 text-slate-400 hover:text-slate-600">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" /></svg>
            </button>
            
            <h2 class={"text-2xl font-black mb-2 " <> if @dark_mode, do: "text-white", else: "text-slate-900"}><%= if @auth_modal == :login, do: "Welcome Back", else: "Join Studymate" %></h2>
            <p class="text-slate-500 mb-6 text-sm"><%= if @auth_modal == :login, do: "Log in to sync your progress.", else: "Create an account to start tracking stats." %></p>

            <.form for={@auth_form} phx-submit={if @auth_modal == :login, do: "perform_login", else: "perform_register"} class="space-y-4">
              <div>
                <label class="block text-[10px] font-black uppercase tracking-widest text-slate-400 mb-1">Email</label>
                <.input field={@auth_form[:email]} type="email" placeholder="you@example.com" class={"w-full p-3 rounded-xl border outline-none focus:ring-2 focus:ring-indigo-500 " <> if @dark_mode, do: "bg-slate-800 border-slate-700 text-white placeholder-slate-500", else: "bg-slate-50 border-slate-200"} required />
              </div>
              <div>
                <label class="block text-[10px] font-black uppercase tracking-widest text-slate-400 mb-1">Password</label>
                <.input field={@auth_form[:password]} type="password" placeholder="••••••••" class={"w-full p-3 rounded-xl border outline-none focus:ring-2 focus:ring-indigo-500 " <> if @dark_mode, do: "bg-slate-800 border-slate-700 text-white placeholder-slate-500", else: "bg-slate-50 border-slate-200"} required />
              </div>
              
              <button class="w-full py-4 mt-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl font-bold shadow-lg transition-all active:scale-95">
                <%= if @auth_modal == :login, do: "Log In", else: "Create Account" %>
              </button>
            </.form>
            
            <div class="mt-6 text-center text-xs text-slate-400">
              <%= if @auth_modal == :login do %>
                New here? <button phx-click="open_register" class="text-indigo-500 font-bold hover:underline">Sign Up</button>
              <% else %>
                Already have an account? <button phx-click="open_login" class="text-indigo-500 font-bold hover:underline">Log In</button>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>

      <div class="max-w-5xl mx-auto">
        
        <!-- Top Status Bar -->
        <div class="flex justify-between items-center mb-6">
          <div class="flex gap-4">
             <div class={"px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest " <> if @current_user, do: "bg-emerald-500/10 text-emerald-500 border border-emerald-500/20", else: "bg-amber-500/10 text-amber-500 border border-amber-500/20"}>
               <%= if @current_user, do: "Member", else: "Guest Mode" %>
             </div>
          </div>
          <%= if !@current_user do %>
            <div class="flex gap-4 text-[10px] font-black uppercase tracking-widest">
               <button phx-click="open_login" class="text-slate-400 hover:text-indigo-500">Log In</button>
               <button phx-click="open_register" class="text-indigo-600 hover:underline">Sign Up</button>
            </div>
          <% else %>
            <div class="flex items-center gap-3">
              <span class="text-[10px] font-black uppercase text-slate-400">Hi, <%= String.split(@current_user.email, "@") |> hd() %></span>
              <button phx-click="logout" class="text-[10px] font-black uppercase text-red-400 hover:text-red-500">Log Out</button>
            </div>
          <% end %>
        </div>

        <!-- Navigation -->
        <header class="flex flex-col md:flex-row justify-between items-center mb-10 gap-6">
          <div class="flex items-center gap-3 cursor-pointer group" phx-click="set_tab" phx-value-tab="home">
            <div class="w-12 h-12 bg-indigo-600 rounded-2xl flex items-center justify-center text-white font-black group-hover:rotate-12 transition-transform shadow-lg text-xl">S</div>
            <h1 class={"text-2xl font-black tracking-tight uppercase " <> if @dark_mode, do: "text-white", else: "text-slate-800"}>Studymate</h1>
          </div>
          
          <div class="flex flex-col sm:flex-row items-center gap-4 w-full md:w-auto">
             <!-- Deck Selector -->
             <div class={"flex items-center gap-2 px-4 py-2 rounded-xl border " <> if @dark_mode, do: "bg-slate-900 border-slate-800", else: "bg-white border-slate-200"}>
               <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" /></svg>
               <form phx-change="select_deck">
                 <select name="deck" class={"bg-transparent text-xs font-bold uppercase tracking-widest outline-none border-none focus:ring-0 cursor-pointer " <> if @dark_mode, do: "text-white", else: "text-slate-700"}>
                   <%= for deck <- @decks do %>
                     <option value={deck} selected={@current_deck == deck} class="text-slate-800"><%= deck %></option>
                   <% end %>
                 </select>
               </form>
             </div>

             <!-- Theme Toggle -->
             <button phx-click="toggle_dark_mode" class={"p-2.5 rounded-xl transition-all active:scale-90 " <> if @dark_mode, do: "bg-slate-900 text-amber-400 hover:bg-slate-800 border border-slate-800", else: "bg-white text-slate-500 border border-slate-200 hover:bg-slate-100 shadow-sm"}>
              <%= if @dark_mode do %>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" clip-rule="evenodd" /></svg>
              <% else %>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" /></svg>
              <% end %>
            </button>

            <!-- Nav -->
            <nav class={"flex flex-wrap justify-center gap-1 p-1.5 rounded-2xl shadow-sm border " <> if @dark_mode, do: "bg-slate-900 border-slate-800", else: "bg-white border-slate-200"}>
              <%= for {tab, label, restricted} <- [{"home", "Home", false}, {"review", "Review", false}, {"quiz", "Quiz", false}, {"rooms", "Live Rooms", true}, {"leaderboard", "Leaderboard", true}, {"manage", "Decks", false}] do %>
                <button 
                  phx-click="set_tab" 
                  phx-value-tab={tab} 
                  class={"relative px-4 py-2 rounded-xl text-sm font-bold transition-all whitespace-nowrap flex items-center gap-2 " <> if @active_tab == tab, do: "bg-indigo-600 text-white shadow-lg", else: (if @dark_mode, do: "text-slate-400 hover:text-slate-100", else: "text-slate-500 hover:text-slate-800")}>
                  <%= label %>
                  <%= if restricted and !@current_user do %>
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 opacity-40" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clip-rule="evenodd" /></svg>
                  <% end %>
                </button>
              <% end %>
            </nav>
          </div>
        </header>

        <!-- MAIN VIEWS -->
        <%= if @active_tab == "home" do %>
          <div class="animate-in fade-in slide-in-from-bottom-4 duration-500 space-y-8">
            <div class="bg-indigo-700 rounded-[2.5rem] p-10 text-white shadow-2xl relative overflow-hidden">
               <div class="relative z-10">
                 <h2 class="text-4xl font-black mb-2">Hello, <%= if @current_user, do: "Scholar", else: "Guest" %>!</h2>
                 <p class="text-indigo-100 italic">Total Session Focus: <%= format_time(@timer_seconds) %></p>
                 <%= if @current_deck != "All Decks" do %>
                   <div class="mt-4 inline-block bg-white/10 px-4 py-1 rounded-full text-xs font-bold border border-white/20">
                     Current Deck: <%= @current_deck %>
                   </div>
                 <% end %>
                 
                 <%= if !@current_user do %>
                  <div class="mt-6 p-4 bg-white/10 rounded-2xl border border-white/10 max-w-md">
                    <p class="text-xs font-bold uppercase tracking-widest text-indigo-200 mb-2">Registration Benefit</p>
                    <p class="text-sm text-white/80">Create private study rooms, join the leaderboard, and share decks via QR code.</p>
                  </div>
                 <% end %>
               </div>
               <div class="absolute -right-10 -bottom-10 w-48 h-48 bg-white opacity-5 rounded-full"></div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              <div phx-click="set_tab" phx-value-tab="review" class={"p-6 rounded-3xl border cursor-pointer group transition-all shadow-sm " <> if @dark_mode, do: "bg-slate-900 border-slate-800 hover:border-indigo-500", else: "bg-white border-slate-100 hover:border-indigo-400"}>
                <h3 class="text-lg font-bold">Start Review</h3>
                <p class="text-xs text-slate-400 mt-1">Solo session</p>
              </div>
              <div phx-click="set_tab" phx-value-tab="rooms" class={"p-6 rounded-3xl border cursor-pointer group transition-all shadow-sm " <> if @dark_mode, do: "bg-slate-900 border-slate-800 hover:border-emerald-500", else: "bg-white border-slate-100 hover:border-emerald-400"}>
                <h3 class="text-lg font-bold">Invite to Quiz</h3>
                <p class="text-xs text-slate-400 mt-1">Multiplayer mode</p>
              </div>
              <div phx-click="set_tab" phx-value-tab="leaderboard" class={"p-6 rounded-3xl border cursor-pointer group transition-all shadow-sm " <> if @dark_mode, do: "bg-slate-900 border-slate-800 hover:border-amber-500", else: "bg-white border-slate-100 hover:border-amber-400"}>
                <h3 class="text-lg font-bold">Leaderboard</h3>
                <p class="text-xs text-slate-400 mt-1">Rankings & Streaks</p>
              </div>
            </div>
          </div>
        <% end %>

        <!-- LIVE ROOMS VIEW -->
        <%= if @active_tab == "rooms" do %>
          <div class="animate-in slide-in-from-bottom-6 duration-500">
            <%= if !@current_user do %>
              <div class={"text-center py-24 rounded-[3rem] border border-dashed " <> if @dark_mode, do: "bg-slate-900/50 border-slate-800", else: "bg-slate-50 border-slate-200"}>
                <h2 class={"text-2xl font-black mb-4 uppercase italic " <> if @dark_mode, do: "text-white", else: "text-slate-800"}>Members Only</h2>
                <p class="text-slate-400 max-w-sm mx-auto mb-8">Login to create high-stakes quiz rooms and invite your classmates to study together in real-time.</p>
                <button phx-click="open_register" class="px-8 py-4 bg-indigo-600 text-white rounded-2xl font-black uppercase tracking-widest shadow-xl hover:bg-indigo-700">Unlock Multiplayer</button>
              </div>
            <% else %>
              <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <div class={"lg:col-span-2 p-10 rounded-[3rem] border " <> if @dark_mode, do: "bg-slate-900 border-slate-800", else: "bg-white border-slate-200"}>
                  <h2 class="text-3xl font-black mb-2 uppercase tracking-tighter">Live Study Room</h2>
                  <p class="text-slate-400 mb-8">Collaborative learning session</p>
                  
                  <%= if !@room_code do %>
                    <button phx-click="create_room" class="w-full py-8 border-2 border-dashed border-indigo-500 rounded-[2rem] text-indigo-500 font-black uppercase tracking-widest hover:bg-indigo-500/5 transition-all">
                      + Create New Room
                    </button>
                  <% else %>
                    <div class="bg-indigo-600 p-8 rounded-[2rem] text-white text-center shadow-2xl">
                      <span class="text-[10px] font-black uppercase tracking-[0.4em] opacity-60">Your Invite Code</span>
                      <h3 class="text-6xl font-black my-4 tracking-widest"><%= @room_code %></h3>
                      <p class="text-indigo-100 text-xs">Share this with friends to join the session</p>
                    </div>
                  <% end %>
                </div>

                <div class={"p-8 rounded-[3rem] border " <> if @dark_mode, do: "bg-slate-900 border-slate-800", else: "bg-white border-slate-200"}>
                   <h3 class="font-black text-xs uppercase tracking-widest mb-6">Who's Studying?</h3>
                   <div class="space-y-3">
                      <div class="flex items-center gap-3">
                         <div class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></div>
                         <span class="text-sm font-bold">You (Host)</span>
                      </div>
                      <div class={"p-4 rounded-2xl text-center text-[10px] font-black text-slate-400 uppercase tracking-widest " <> if @dark_mode, do: "bg-slate-800/50", else: "bg-slate-50"}>
                        Waiting for friends...
                      </div>
                   </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>

        <!-- LEADERBOARD VIEW -->
        <%= if @active_tab == "leaderboard" do %>
          <div class="animate-in slide-in-from-bottom-6 duration-500">
            <%= if !@current_user do %>
               <div class={"text-center py-24 rounded-[3rem] border border-dashed " <> if @dark_mode, do: "bg-slate-900/50 border-slate-800", else: "bg-slate-50 border-slate-200"}>
                <h2 class={"text-2xl font-black mb-4 uppercase italic " <> if @dark_mode, do: "text-white", else: "text-slate-800"}>Members Only</h2>
                <p class="text-slate-400 max-w-sm mx-auto mb-8">Join the community to compete on the global leaderboard and track your daily streaks.</p>
                <button phx-click="open_register" class="px-8 py-4 bg-indigo-600 text-white rounded-2xl font-black uppercase tracking-widest shadow-xl hover:bg-indigo-700">Join Leaderboard</button>
              </div>
            <% else %>
              <div class={"p-8 rounded-[2.5rem] border shadow-sm " <> if @dark_mode, do: "bg-slate-900 border-slate-800", else: "bg-white border-slate-200"}>
                <div class="flex justify-between items-end mb-8">
                  <div>
                    <h2 class="text-3xl font-black mb-2 uppercase tracking-tighter">Top Learners</h2>
                    <p class="text-slate-400 text-sm">Ranked by daily flashcard activity</p>
                  </div>
                  <div class="text-right">
                    <p class="text-[10px] font-bold uppercase tracking-widest text-indigo-500">Your Rank</p>
                    <p class="text-2xl font-black">#42</p>
                  </div>
                </div>

                <div class="space-y-2">
                  <!-- Header Row -->
                  <div class="grid grid-cols-12 gap-4 px-4 py-2 text-[10px] font-black uppercase tracking-widest text-slate-400">
                    <div class="col-span-1 text-center">#</div>
                    <div class="col-span-5">User</div>
                    <div class="col-span-3 text-center">Streak</div>
                    <div class="col-span-3 text-right">XP Today</div>
                  </div>
                  
                  <%= for user <- @leaderboard_data do %>
                    <div class={"grid grid-cols-12 gap-4 px-4 py-4 rounded-2xl items-center transition-all " <> 
                      if(@dark_mode, do: "bg-slate-800/50 hover:bg-slate-800", else: "bg-slate-50 hover:bg-slate-100") <> 
                      if(user.rank <= 3, do: " border border-indigo-500/30", else: " border border-transparent")
                    }>
                      <div class="col-span-1 text-center font-black text-lg">
                        <%= case user.rank do %>
                          <% 1 -> %> 🥇
                          <% 2 -> %> 🥈
                          <% 3 -> %> 🥉
                          <% _ -> %><%= user.rank %>
                        <% end %>
                      </div>
                      <div class="col-span-5 flex items-center gap-3">
                        <div class={"w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold text-white " <> 
                          case user.rank do
                            1 -> "bg-amber-400"
                            2 -> "bg-slate-400"
                            3 -> "bg-amber-700"
                            _ -> "bg-indigo-500"
                          end
                        }>
                          <%= String.at(user.name, 0) %>
                        </div>
                        <span class="font-bold text-sm truncate"><%= user.name %></span>
                      </div>
                      <div class="col-span-3 text-center font-bold">
                        🔥 <%= user.streak %>
                      </div>
                      <div class="col-span-3 text-right font-black text-indigo-500">
                        <%= user.xp %> XP
                      </div>
                    </div>
                  <% end %>

                   <!-- Current User Row Mockup -->
                   <div class={"grid grid-cols-12 gap-4 px-4 py-4 rounded-2xl items-center mt-4 border-2 " <> if @dark_mode, do: "bg-indigo-900/20 border-indigo-500", else: "bg-indigo-50 border-indigo-200"}>
                      <div class="col-span-1 text-center font-black text-lg text-indigo-500">42</div>
                      <div class="col-span-5 flex items-center gap-3">
                        <div class="w-8 h-8 rounded-full bg-indigo-600 flex items-center justify-center text-xs font-bold text-white">
                           <%= if @current_user, do: String.at(String.split(@current_user.email, "@") |> hd(), 0) |> String.upcase(), else: "U" %>
                        </div>
                        <span class="font-bold text-sm truncate">You</span>
                      </div>
                      <div class="col-span-3 text-center font-bold text-slate-500">
                        🔥 14
                      </div>
                      <div class="col-span-3 text-right font-black text-indigo-600">
                        <%= @session_stats.total * 20 %> XP
                      </div>
                    </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>

        <!-- MANAGE VIEW (Sharing Logic) -->
        <%= if @active_tab == "manage" do %>
          <div class="animate-in fade-in duration-500 space-y-8">
            
            <!-- SHARE PANEL -->
            <div class={"p-8 rounded-[2.5rem] border overflow-hidden relative " <> if @dark_mode, do: "bg-slate-900 border-slate-800", else: "bg-white border-slate-200"}>
              <div class="flex justify-between items-start mb-6">
                <h2 class="text-xl font-black uppercase tracking-tight">Deck Management</h2>
                <%= if @current_user do %>
                  <button phx-click="toggle_share" class={"px-5 py-2.5 rounded-xl text-[10px] font-black uppercase tracking-widest border transition-all flex items-center gap-2 " <> if @is_public, do: "bg-emerald-500 text-white border-emerald-500", else: "text-slate-400 border-slate-200 hover:border-slate-400"}>
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" /></svg>
                    <%= if @is_public, do: "Share " <> @current_deck, else: "Share Deck" %>
                  </button>
                <% else %>
                   <button phx-click="open_login" class="text-[10px] font-black uppercase text-slate-300 tracking-widest hover:text-indigo-500">Login to Share</button>
                <% end %>
              </div>

              <%= if @is_public and @current_user do %>
                <div class={"p-6 rounded-3xl border border-dashed border-emerald-500/30 flex flex-col md:flex-row items-center gap-8 animate-in slide-in-from-top-2 " <> if @dark_mode, do: "bg-black/20", else: "bg-slate-50"}>
                  <div class="bg-white p-3 rounded-2xl shadow-sm">
                    <img src={"https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=#{@share_link}&color=4338ca"} alt="QR Code" class="w-32 h-32 rounded-lg" />
                  </div>
                  <div class="flex-1 text-center md:text-left">
                    <h3 class="text-lg font-black text-emerald-600 mb-1">Deck is Public!</h3>
                    <p class="text-xs text-slate-500 mb-4">Anyone with this QR code can clone the <strong><%= @current_deck %></strong> deck.</p>
                    <div class="flex gap-2">
                       <input readonly value={@share_link} class={"flex-1 border-none rounded-xl text-xs px-4 font-mono " <> if @dark_mode, do: "bg-slate-800 text-slate-400", else: "bg-white text-slate-500"} />
                       <button class="bg-slate-800 text-white px-4 py-3 rounded-xl font-bold text-xs">Copy</button>
                    </div>
                  </div>
                </div>
              <% end %>

              <.form for={@form} phx-submit="save" class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-6">
                <div class="md:col-span-2">
                   <label class="block text-[10px] font-black uppercase tracking-widest text-slate-400 mb-1">Select or Create Deck Category</label>
                   <input list="deck-suggestions" name="flashcard[category]" placeholder="General" class={"w-full p-4 rounded-xl border outline-none focus:ring-2 focus:ring-indigo-500 " <> if @dark_mode, do: "bg-slate-800 border-slate-700 text-white", else: "bg-slate-50 border-slate-200"} required />
                   <datalist id="deck-suggestions">
                      <%= for deck <- @decks, deck != "All Decks" do %>
                        <option value={deck} />
                      <% end %>
                   </datalist>
                </div>
                <.input field={@form[:term]} placeholder="Term" class={"rounded-xl p-4 " <> if @dark_mode, do: "bg-slate-800 border-slate-700 text-white placeholder-slate-500 focus:ring-indigo-500", else: ""} />
                <.input field={@form[:definition]} placeholder="Definition" class={"rounded-xl p-4 " <> if @dark_mode, do: "bg-slate-800 border-slate-700 text-white placeholder-slate-500 focus:ring-indigo-500", else: ""} />
                <button class="md:col-span-2 bg-indigo-600 text-white py-4 rounded-2xl font-bold hover:bg-indigo-700 shadow-md">Add to Deck</button>
              </.form>
            </div>

            <div class="grid grid-cols-1 gap-3">
              <% filtered_cards = filter_cards(@flashcards, @current_deck, @search_query) %>
              <%= for card <- filtered_cards do %>
                <div class={"p-5 rounded-2xl border flex justify-between items-center transition-all " <> if @dark_mode, do: "bg-slate-900 border-slate-800 hover:border-slate-700", else: "bg-white border-slate-100 hover:border-indigo-100"}>
                  <div>
                    <div class="flex items-center gap-2 mb-1">
                      <span class="text-[8px] font-black uppercase px-2 py-0.5 rounded bg-indigo-100 text-indigo-600 dark:bg-indigo-900/50 dark:text-indigo-300"><%= card.category %></span>
                    </div>
                    <p class="font-bold text-lg"><%= card.term %></p>
                    <p class="text-sm text-slate-400 mt-1"><%= card.definition %></p>
                  </div>
                  <button phx-click="delete" phx-value-id={card.id} class="text-slate-400 hover:text-red-500 transition-colors">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                  </button>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>

        <!-- (Review & Quiz templates remain as per original logic) -->
        <%= if @active_tab == "review" do %>
          <div class="flex flex-col items-center animate-in zoom-in-95 duration-500">
             <div class="w-full max-w-md flex justify-end mb-6">
                <button phx-click="toggle_reverse" class={"text-[10px] font-black uppercase tracking-widest flex items-center gap-2 px-5 py-2.5 rounded-xl transition-all shadow-sm " <> if @reverse_mode, do: "bg-indigo-600 text-white shadow-indigo-900/20", else: (if @dark_mode, do: "bg-slate-900 text-slate-400 border border-slate-800", else: "bg-white text-slate-400 border border-slate-200")}>
                  Reverse Mode <%= if @reverse_mode, do: "ON", else: "OFF" %>
                </button>
              </div>
              
              <% active_cards = filter_cards(@flashcards, @current_deck, @search_query) %>
              <%= if length(active_cards) > 0 do %>
                <% current = Enum.at(active_cards, @current_index) || Enum.at(active_cards, 0) %>
                <% front_content = if @reverse_mode, do: current.term, else: current.definition %>
                <% back_content = if @reverse_mode, do: current.definition, else: current.term %>
                
                <div class="w-full max-w-md h-96 cursor-pointer group" style="perspective: 1000px;" phx-click="flip">
                  <div class={"relative w-full h-full transition-all duration-500 " <> if @is_flipped, do: "[transform:rotateY(180deg)]", else: "" } style="transform-style: preserve-3d;">
                    <div class={"absolute inset-0 border-2 rounded-[3rem] shadow-2xl flex flex-col items-center justify-center p-12 text-center [backface-visibility:hidden] " <> if @dark_mode, do: "bg-slate-900 border-slate-800", else: "bg-white border-slate-200"}>
                      <span class="text-[10px] font-black uppercase tracking-[0.3em] text-indigo-500 mb-6">Front</span>
                      <p class="text-2xl md:text-3xl font-bold leading-tight transition-colors"><%= front_content %></p>
                      <div class="mt-10 opacity-0 group-hover:opacity-100 transition-opacity flex items-center gap-2 text-slate-400 font-bold text-xs uppercase tracking-widest">Click to flip</div>
                    </div>
                    <div class="absolute inset-0 bg-indigo-600 text-white rounded-[3rem] shadow-2xl flex flex-col items-center justify-center p-12 text-center [backface-visibility:hidden] [transform:rotateY(180deg)]">
                      <span class="text-[10px] font-black uppercase tracking-[0.3em] text-indigo-200 mb-6">Answer</span>
                      <p class="text-3xl md:text-4xl font-black tracking-tight"><%= back_content %></p>
                    </div>
                  </div>
                </div>
                <div class="mt-10 flex gap-8 items-center">
                  <button phx-click="prev" class={"p-5 border rounded-full shadow-sm transition-all hover:scale-110 active:scale-90 " <> if @dark_mode, do: "bg-slate-900 border-slate-800 text-slate-400", else: "bg-white border-slate-200 text-slate-400"}>←</button>
                  <div class="text-center">
                     <span class="text-lg font-black tracking-tighter text-indigo-600"><%= @current_index + 1 %> / <%= length(active_cards) %></span>
                  </div>
                  <button phx-click="next" class="p-5 bg-indigo-600 text-white rounded-full shadow-lg hover:bg-indigo-700 hover:scale-110 active:scale-90 transition-all">→</button>
                </div>
              <% else %>
                 <div class={"text-center py-20 rounded-[3rem] border border-dashed w-full " <> if @dark_mode, do: "bg-slate-900 border-slate-800 text-slate-500", else: "bg-white border-slate-200 text-slate-400"}>
                   <p>No cards in this deck.</p>
                 </div>
              <% end %>
          </div>
        <% end %>

        <%= if @active_tab == "quiz" do %>
          <div class="max-w-2xl mx-auto animate-in slide-in-from-bottom-6 duration-500">
            <% active_cards = filter_cards(@flashcards, @current_deck, @search_query) %>
            <%= if length(active_cards) < 4 do %>
              <div class={"text-center py-20 rounded-[3rem] border border-dashed transition-colors " <> if @dark_mode, do: "bg-slate-900 border-slate-800 text-slate-500", else: "bg-white border-slate-200 text-slate-400"}>Needs 4 cards in this deck to start quiz.</div>
            <% else %>
              <% current = Enum.at(active_cards, @current_index) || Enum.at(active_cards, 0) %>
              <% question_content = if @reverse_mode, do: current.term, else: current.definition %>
              <div class={"p-10 md:p-16 rounded-[3rem] shadow-2xl border text-center relative overflow-hidden transition-colors " <> if @dark_mode, do: "bg-slate-900 border-slate-800", else: "bg-white border-slate-100"}>
                <h3 class={"text-2xl md:text-4xl font-serif italic mb-12 leading-snug transition-colors " <> if @dark_mode, do: "text-slate-200", else: "text-slate-700"}>"<%= question_content %>"</h3>
                <%= if !@quiz_feedback do %>
                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <%= for opt <- @mcq_options do %>
                      <button phx-click="select_mcq" phx-value-ans={opt} class={"p-6 rounded-2xl border-2 font-bold transition-all text-lg active:scale-95 shadow-sm " <> if @dark_mode, do: "bg-slate-800 border-slate-700 text-slate-200 hover:border-indigo-600", else: "bg-white border-slate-100 text-slate-600 hover:border-indigo-500 hover:bg-indigo-50"}>
                        <%= opt %>
                      </button>
                    <% end %>
                  </div>
                <% else %>
                  <div class={"p-10 rounded-[2.5rem] animate-in zoom-in-95 duration-300 shadow-xl " <> if @quiz_feedback.correct, do: "bg-green-50 text-green-700", else: "bg-red-50 text-red-700"}>
                    <p class="text-3xl font-black mb-8"><%= @quiz_feedback.msg %></p>
                    <button phx-click="next" class="bg-white px-12 py-4 rounded-2xl shadow-lg font-black text-slate-800 hover:scale-105 active:scale-95 transition-all uppercase tracking-tight">Next Question →</button>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # --- AUTH EVENTS ---

  @impl
  def handle_event("open_login", _, socket), do: {:noreply, assign(socket, auth_modal: :login)}

  @impl
  def handle_event("open_register", _, socket), do: {:noreply, assign(socket, auth_modal: :register)}

  @impl
  def handle_event("close_auth", _, socket), do: {:noreply, assign(socket, auth_modal: nil)}

  @impl
  def handle_event("logout", _, socket), do: {:noreply, assign(socket, current_user: nil)}

  @impl
  def handle_event("perform_register", %{"user" => params}, socket) do
    case Accounts.register_user(params) do
      {:ok, user} -> 
        {:noreply, 
          socket 
          |> assign(current_user: user, auth_modal: nil) 
          |> put_flash(:info, "Welcome aboard!")}
      {:error, _cs} -> 
        {:noreply, put_flash(socket, :error, "Email already taken or invalid.")}
    end
  end

  @impl
  def handle_event("perform_login", %{"user" => %{"email" => e, "password" => p}}, socket) do
    case Accounts.get_user_by_email_and_password(e, p) do
      {:ok, user} -> 
        {:noreply, assign(socket, current_user: user, auth_modal: nil)}
      {:error, _} -> 
        {:noreply, put_flash(socket, :error, "Invalid credentials.")}
    end
  end

  # --- STANDARD EVENTS ---

  @impl
  def handle_event("create_room", _, socket) do
    # In a real app, you would use Phoenix PubSub to subscribe to "room:#{code}"
    code = to_string(Enum.random(100_000..999_999))
    {:noreply, assign(socket, room_code: code)}
  end

  @impl
  def handle_event("toggle_share", _, socket) do
    share_code = if !socket.assigns.is_public, do: "https://studymate.app/share/#{socket.assigns.current_deck}", else: nil
    {:noreply, assign(socket, is_public: !socket.assigns.is_public, share_link: share_code)}
  end

  @impl
  def handle_event("toggle_dark_mode", _, socket), do: {:noreply, assign(socket, dark_mode: !socket.assigns.dark_mode)}

  @impl
  def handle_event("toggle_reverse", _, socket) do
    socket = socket |> assign(reverse_mode: !socket.assigns.reverse_mode)
    socket = if socket.assigns.active_tab == "quiz" and socket.assigns.quiz_mode == "mcq", 
      do: assign_mcq_options(socket), 
      else: socket
    {:noreply, socket}
  end

  @impl
  def handle_event("set_tab", %{"tab" => t}, socket) do
    # Prevent Guest from opening rooms or leaderboard
    socket = if (t == "rooms" or t == "leaderboard") and !socket.assigns.current_user do
       socket |> assign(active_tab: t)
    else
       socket |> assign(active_tab: t, quiz_feedback: nil, is_flipped: false, search_query: "")
    end
    socket = if t == "quiz", do: assign_mcq_options(socket), else: socket
    {:noreply, socket}
  end

  @impl
  def handle_event("select_deck", %{"deck" => deck}, socket) do
    {:noreply, assign(socket, current_deck: deck, current_index: 0, is_flipped: false) |> assign_mcq_options()}
  end

  @impl
  def handle_event("select_mcq", %{"ans" => ans}, socket) do
    current = Enum.at(filter_cards(socket.assigns.flashcards, socket.assigns.current_deck, ""), socket.assigns.current_index)
    correct_ans = if socket.assigns.reverse_mode, do: current.definition, else: current.term
    correct = ans == correct_ans
    update_stats_and_feedback(socket, correct, if(correct, do: "Spot on!", else: "Not quite. Answer: #{correct_ans}"))
  end

  @impl
  def handle_event("save", %{"flashcard" => params}, socket) do
    case Study.create_flashcard(params) do
      {:ok, _} -> 
        updated_cards = Study.list_flashcards()
        decks = ["All Decks" | (updated_cards |> Enum.map(& &1.category) |> Enum.uniq() |> Enum.sort())]
        {:noreply, assign(socket, flashcards: updated_cards, decks: decks)}
      {:error, cs} -> 
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  @impl
  def handle_event("delete", %{"id" => id}, socket) do
    Study.delete_flashcard(Study.get_flashcard!(id))
    updated_cards = Study.list_flashcards()
    decks = ["All Decks" | (updated_cards |> Enum.map(& &1.category) |> Enum.uniq() |> Enum.sort())]
    {:noreply, assign(socket, flashcards: updated_cards, decks: decks)}
  end

  @impl
  def handle_event("flip", _, socket), do: {:noreply, assign(socket, is_flipped: !socket.assigns.is_flipped)}

  @impl
  def handle_event("next", _, socket) do
    filtered = filter_cards(socket.assigns.flashcards, socket.assigns.current_deck, "")
    idx = if socket.assigns.current_index + 1 >= length(filtered), do: 0, else: socket.assigns.current_index + 1
    socket = socket |> assign(current_index: idx, is_flipped: false, quiz_feedback: nil)
    socket = if socket.assigns.active_tab == "quiz", do: assign_mcq_options(socket), else: socket
    {:noreply, socket}
  end

  @impl
  def handle_event("prev", _, socket), do: {:noreply, assign(socket, current_index: max(0, socket.assigns.current_index - 1), is_flipped: false, quiz_feedback: nil)}

  # --- HELPERS ---

  defp filter_cards(cards, "All Decks", ""), do: cards
  defp filter_cards(cards, "All Decks", query), do: Enum.filter(cards, &String.contains?(String.downcase(&1.term <> &1.definition), String.downcase(query)))
  defp filter_cards(cards, deck, ""), do: Enum.filter(cards, & &1.category == deck)
  defp filter_cards(cards, deck, query), do: Enum.filter(cards, & &1.category == deck and String.contains?(String.downcase(&1.term <> &1.definition), String.downcase(query)))

  defp update_stats_and_feedback(socket, correct, msg) do
    stats = socket.assigns.session_stats
    new_stats = %{correct: stats.correct + (if correct, do: 1, else: 0), total: stats.total + 1}
    {:noreply, assign(socket, session_stats: new_stats, quiz_feedback: %{correct: correct, msg: msg})}
  end

  defp assign_mcq_options(socket) do
    filtered = filter_cards(socket.assigns.flashcards, socket.assigns.current_deck, "")
    if length(filtered) > 0 do
       current = Enum.at(filtered, socket.assigns.current_index) || Enum.at(filtered, 0)
       correct_ans = if socket.assigns.reverse_mode, do: current.definition, else: current.term
       wrong = socket.assigns.flashcards 
               |> Enum.filter(& &1.id != current.id) 
               |> Enum.shuffle() 
               |> Enum.take(3) 
               |> Enum.map(fn c -> if socket.assigns.reverse_mode, do: c.definition, else: c.term end)
       assign(socket, :mcq_options, Enum.shuffle([correct_ans | wrong]))
    else
       assign(socket, :mcq_options, [])
    end
  end

  defp calculate_accuracy(0, 0), do: 0
  defp calculate_accuracy(correct, total), do: round((correct / total) * 100)

  defp format_time(seconds) do
    min = div(seconds, 60)
    sec = rem(seconds, 60)
    "#{min}m #{String.pad_leading(Integer.to_string(sec), 2, "0")}s"
  end
end